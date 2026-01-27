# --- KONFIGURATION ---
$VersionUrl = "https://github.com/ammicon/downloads/raw/refs/heads/main/teamsbackgrounds/version.txt"
$ZipUrl = "https://github.com/ammicon/downloads/raw/refs/heads/main/teamsbackgrounds/ammicon_teamsbackgrounds.zip" # Nutze den RAW-Link
$TargetDir = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"
$VersionFile = Join-Path $TargetDir "version.txt" # Lokale Marker-Datei

try {
    # 1. Zielverzeichnis erstellen falls es nicht existiert
    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force
        Write-Host "Zielverzeichnis erstellt: $TargetDir"
    } else {
        Write-Host "Zielverzeichnis existiert bereits: $TargetDir"
    }

    # 2. Aktuelle Version von GitHub abrufen
    $NewVersion = (Invoke-WebRequest -Uri $VersionUrl -UseBasicParsing).Content.Trim()
    Write-Host "Neue Version: $NewVersion"
    
    # 3. Download & Extraktion
    $TempZip = "$env:TEMP\ammicon_teamsbackgrounds.zip"
    $TempExtract = "$env:TEMP\ammicon_teamsbackgrounds_extracted"
    Write-Host "Temp-Verzeichnisse: ZIP=$TempZip, Extraktion=$TempExtract"
    
    if (Test-Path $TempExtract) { 
        Remove-Item -Recurse -Force $TempExtract 
        Write-Host "Altes Temp-Verzeichnis entfernt"
    }
    New-Item -ItemType Directory -Path $TempExtract -Force
    
    Write-Host "Lade ZIP-Datei herunter..."
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
    Write-Host "ZIP-Datei heruntergeladen, extrahiere..."
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
    Write-Host "ZIP-Datei extrahiert"
    
    # Alle Dateien im extrahierten Verzeichnis anzeigen
    Write-Host "Inhalt des extrahierten Verzeichnisses:"
    Get-ChildItem -Path $TempExtract -Recurse | ForEach-Object { Write-Host "  $($_.FullName)" }

    # 4. Bildverarbeitung mit UUID-Unterstuetzung
    Add-Type -AssemblyName System.Drawing
    $Images = Get-ChildItem -Path $TempExtract -File -Recurse | Where-Object { 
        $_.Extension -match '\.(png|jpg|jpeg)$' -and 
        !$_.Name.StartsWith('._') -and 
        !$_.Name.StartsWith('.DS_Store')
    }
    Write-Host "Gefundene Bilddateien: $($Images.Count)"
    
    if ($Images.Count -eq 0) {
        Write-Host "WARNUNG: Keine Bilddateien gefunden!"
        # Alle Dateien anzeigen
        Get-ChildItem -Path $TempExtract -Recurse | ForEach-Object { Write-Host "  Datei: $($_.Name), Erweiterung: $($_.Extension)" }
    }
    
    foreach ($Image in $Images) {
        # UUID aus Dateiname extrahieren (ohne Erweiterung)
        $ImageGuid = $Image.BaseName
        Write-Host "Verarbeite Bild: $ImageGuid (Datei: $($Image.Name))"
        
        try {
            $Bmp = [System.Drawing.Bitmap]::FromFile($Image.FullName)
            $ImagePath = Join-Path $TargetDir "$ImageGuid.png"
            $ThumbPath = Join-Path $TargetDir "$($ImageGuid)_thumb.png"
            
            # Hauptbild speichern
            $Bmp.Save($ImagePath, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Host "Hauptbild gespeichert: $ImagePath"
            
            # Thumbnail erstellen und speichern
            $Thumb = $Bmp.GetThumbnailImage(280, 158, $null, [intptr]::Zero)
            $Thumb.Save($ThumbPath, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Host "Thumbnail gespeichert: $ThumbPath"
            
            $Bmp.Dispose(); $Thumb.Dispose()
            
        } catch {
            Write-Host "Fehler beim Verarbeiten von $($Image.Name): $($_.Exception.Message)"
        }
    }
    
    Write-Host "Bildverarbeitung abgeschlossen."
    Write-Host "Finale Inhalte des Zielverzeichnisses:"
    Get-ChildItem -Path $TargetDir | ForEach-Object { Write-Host "  $($_.Name)" }

    # 5. Versions-Marker lokal speichern
    $NewVersion | Out-File -FilePath $VersionFile -Force
    Write-Host "Version $NewVersion gespeichert"
    
    Write-Host "Rauume temporoere Dateien auf..."
    Remove-Item $TempZip -Force
    Remove-Item -Recurse -Force $TempExtract
    Write-Host "Installation erfolgreich abgeschlossen!"
    exit 0
} catch {
    Write-Host "Fehler aufgetreten: $($_.Exception.Message)"
    exit 1
}
