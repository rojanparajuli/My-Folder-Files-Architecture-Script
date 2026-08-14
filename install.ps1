# Installs rojanarch as a native binary on Windows — no git, no Dart SDK required.
#
#   iwr https://raw.githubusercontent.com/rojanparajuli/My-Folder-Files-Architecture-Script/main/install.ps1 -useb | iex
#
$ErrorActionPreference = "Stop"

$Repo = "rojanparajuli/My-Folder-Files-Architecture-Script"
$InstallDir = "$env:LOCALAPPDATA\rojanarch"

Write-Host "Fetching the latest rojanarch release for windows-x64..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
$asset = $release.assets | Where-Object { $_.name -like "*windows-x64.zip" } | Select-Object -First 1

if (-not $asset) {
    Write-Error "Could not find a windows-x64 release asset. Has a release been published yet?"
    exit 1
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$zipPath = Join-Path $env:TEMP "rojanarch.zip"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
Remove-Item $zipPath

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    Write-Host "Added $InstallDir to your user PATH. Restart your terminal for it to take effect."
}

Write-Host ""
Write-Host "Installed rojanarch to $InstallDir"
Write-Host "Run it with: rojanarch"
