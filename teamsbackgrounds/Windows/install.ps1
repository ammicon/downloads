# --- KONFIGURATION ---
$VersionUrl = "https://raw.githubusercontent.com/ammicon/downloads/main/teamsbackgrounds/version.txt"
$ZipUrl = "https://raw.githubusercontent.com/ammicon/downloads/main/teamsbackgrounds/ammicon_teamsbackgrounds.zip" # Nutze den RAW-Link
$TargetDir = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"
$VersionFile = Join-Path $TargetDir "version.txt" # Lokale Marker-Datei

try {
    # 1. Aktuelle Version von GitHub abrufen
    $NewVersion = (Invoke-WebRequest -Uri $VersionUrl -UseBasicParsing).Content.Trim()
    
    # 2. Download & Extraktion
    $TempZip = "$env:TEMP\teams_bg.zip"
    $TempExtract = "$env:TEMP\teams_bg_extracted"
    if (Test-Path $TempExtract) { Remove-Item -Recurse -Force $TempExtract }
    New-Item -ItemType Directory -Path $TempExtract -Force
    
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force

    # 3. Bildverarbeitung (wie bisher)
    Add-Type -AssemblyName System.Drawing
    $Images = Get-ChildItem -Path $TempExtract -Include *.png, *.jpg, *.jpeg -File
    foreach ($Image in $Images) {
        $BaseName = $Image.BaseName
        $Bmp = [System.Drawing.Bitmap]::FromFile($Image.FullName)
        $Bmp.Save((Join-Path $TargetDir "$BaseName.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $Thumb = $Bmp.GetThumbnailImage(280, 158, $null, [intptr]::Zero)
        $Thumb.Save((Join-Path $TargetDir "$($BaseName)_thumb.png"), [System.Drawing.Imaging.ImageFormat]::Png)
        $Bmp.Dispose(); $Thumb.Dispose()
    }

    # 4. Versions-Marker lokal speichern
    $NewVersion | Out-File -FilePath $VersionFile -Force
    
    Remove-Item $TempZip -Force
    Remove-Item -Recurse -Force $TempExtract
    exit 0
} catch {
    exit 1
}
