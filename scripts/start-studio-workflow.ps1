param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$Branch = "main",
    [switch]$SkipRojoServe,
    [switch]$SkipStudioLaunch,
    [switch]$SkipRojoCheck
)

$ErrorActionPreference = "Stop"

$setupScript = Join-Path $PSScriptRoot "setup-dev-env.ps1"
if (-not (Test-Path $setupScript)) {
    throw "Missing setup script: $setupScript"
}

$setupArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $setupScript,
    "-ProjectRoot", $ProjectRoot,
    "-Branch", $Branch
)

if ($SkipRojoCheck) {
    $setupArgs += "-SkipRojoCheck"
}

powershell @setupArgs

if (-not $SkipRojoServe) {
    if (Get-Command rojo -ErrorAction SilentlyContinue) {
        $escapedRoot = $ProjectRoot.Replace("'", "''")
        $rojoCommand = "Set-Location '$escapedRoot'; rojo serve"
        Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-NoExit",
            "-ExecutionPolicy", "Bypass",
            "-Command", $rojoCommand
        ) | Out-Null
        Write-Output "[OK] Started Rojo serve in a new terminal window."
    } else {
        Write-Output "[WARN] Rojo not found in PATH; skipping rojo serve launch."
    }
}

if (-not $SkipStudioLaunch) {
    $versionsRoot = Join-Path $env:LOCALAPPDATA "Roblox\Versions"
    $studioExe = Get-ChildItem -Path $versionsRoot -Filter "RobloxStudioBeta.exe" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName

    if ([string]::IsNullOrWhiteSpace($studioExe)) {
        Write-Output "[WARN] RobloxStudioBeta.exe not found; launch Studio manually."
    } else {
        $placePath = Join-Path $ProjectRoot "Pirateislandfrontiers\Ganestart1.rbxl"
        if (Test-Path $placePath) {
            Start-Process -FilePath $studioExe -ArgumentList @($placePath) | Out-Null
            Write-Output "[OK] Launched Roblox Studio with place file."
        } else {
            Start-Process -FilePath $studioExe | Out-Null
            Write-Output "[OK] Launched Roblox Studio."
        }
    }
}

Write-Output ""
Write-Output "Studio workflow initialized."
Write-Output "In Studio Rojo plugin: connect to localhost:34872 and open default.project.json"
