#!/bin/sh

### Do not modify ###
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
USER_HOME=$(dscl . -read /users/${CURRENT_USER} NFSHomeDirectory | cut -d " " -f 2)
TMPDIR=$(mktemp -d)
BACKGROUND_FOLDER="$USER_HOME/Library/Containers/com.microsoft.teams2/Data/Library/Application Support/Microsoft/MSTeams/Backgrounds/Uploads"

### Required settings ###
BACKGROUND_URL="https://github.com/ammicon/downloads/raw/refs/heads/main/teamsbackgrounds/ammicon_teamsbackgrounds.zip"
VERSION_URL="https://github.com/ammicon/downloads/raw/refs/heads/main/teamsbackgrounds/version.txt"

### Optional settings ###
IMAGE_FORMATS=("png" "jpg" "jpeg")
RUN_CHECK_PATH="$USER_HOME/Library/Application Support/.ammicon_teams_version"

log_message() {
    echo "[$(date)] - $1"
}

# --- Versionsprüfung ---
REMOTE_VERSION=$(curl -sL "$VERSION_URL" | tr -d '[:space:]')
if [ -f "$RUN_CHECK_PATH" ]; then
    LOCAL_VERSION=$(cat "$RUN_CHECK_PATH" | tr -d '[:space:]')
else
    LOCAL_VERSION="0"
fi

if [ "$REMOTE_VERSION" = "$LOCAL_VERSION" ] && [ -n "$REMOTE_VERSION" ]; then
    log_message "Version $LOCAL_VERSION ist aktuell. Beende Skript."
    rm -rf "$TMPDIR"
    exit 0
fi

log_message "Update gefunden: Lokal ($LOCAL_VERSION) -> Remote ($REMOTE_VERSION)"

process_image() {
    local f="$1"
    file_extension="${f##*.}"
    for format in "${IMAGE_FORMATS[@]}"; do
        if [[ "$file_extension" == "$format" ]]; then
            IMAGE_GUID=$(uuidgen)
            IMAGE_PATH="$BACKGROUND_FOLDER/$IMAGE_GUID.png"
            IMAGE_THUMB_PATH="$BACKGROUND_FOLDER/${IMAGE_GUID}_thumb.png"
            
            if [[ $f != *.png ]]; then
                sips -s format png "$f" -o "$f.png" > /dev/null
            fi

            mv "$f" "$IMAGE_GUID"
            cp "$IMAGE_GUID" "$IMAGE_PATH"
            cp "$IMAGE_GUID" "$IMAGE_THUMB_PATH"

            sips -Z 186 "$IMAGE_THUMB_PATH" -o "$IMAGE_THUMB_PATH" > /dev/null 2>&1
            width=$(sips -g pixelWidth "$IMAGE_THUMB_PATH" | awk '/pixelWidth:/{print $2}')
            crop=$((($width - 238) / 2))
            sips -z 186 238 "$IMAGE_THUMB_PATH" -o "$IMAGE_THUMB_PATH" > /dev/null 2>&1

            log_message "Hintergrund gesetzt: $IMAGE_GUID"
        fi
    done
}

# Check Teams
if [ ! -d "/Applications/Microsoft Teams (work or school).app" ]; then
    log_message "Microsoft Teams nicht installiert"
    rm -rf "$TMPDIR"
    exit 1
fi

if [ ! -d "$BACKGROUND_FOLDER" ]; then
    mkdir -p "$BACKGROUND_FOLDER"
fi

cd "$TMPDIR"
curl -f -s -O "$BACKGROUND_URL"

if [ $? == 0 ]; then
    for f in *; do
        if [[ $f == *.zip ]]; then
            unzip -q "$f"
            for extracted in *; do
                process_image "$extracted"
            done
            continue
        fi
        process_image "$f"
    done

    # Speichere die neue Version lokal, damit beim nächsten Lauf "aktuell" gemeldet wird
    echo "$REMOTE_VERSION" > "$RUN_CHECK_PATH"
    log_message "Version $REMOTE_VERSION erfolgreich installiert und gespeichert."

    rm -rf "$TMPDIR"
    exit 0
else
    log_message "Download fehlgeschlagen"
    rm -rf "$TMPDIR"
    exit 1
fi
