$VersionUrl = "https://github.com/ammicon/downloads/raw/refs/heads/main/teamsbackgrounds/version.txt"
$TargetDir = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"
$VersionFile = Join-Path $TargetDir "bg_version.txt"

try {
    # Falls Datei nicht existiert -> Neuinstallation
    if (!(Test-Path $VersionFile)) { exit 1 }

    # Versionen vergleichen
    $LocalVersion = (Get-Content $VersionFile).Trim()
    $RemoteVersion = (Invoke-WebRequest -Uri $VersionUrl -UseBasicParsing).Content.Trim()

    if ($LocalVersion -eq $RemoteVersion) {
        Write-Output "Version $LocalVersion ist aktuell."
        exit 0 # Alles okay, keine Aktion nötig
    } else {
        exit 1 # Update erforderlich
    }
} catch {
    exit 1 # Im Fehlerfall lieber neu installieren
}
