param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$Branch = "main",
    [string]$RepoUrl = "https://github.com/0x12371C/justins-game.git",
    [switch]$SkipRojoCheck
)

$ErrorActionPreference = "Stop"

Set-Location $ProjectRoot

if (-not (Test-Path ".git")) {
    throw "Not a git repository: $ProjectRoot"
}

$originUrl = ""
try {
    $originUrl = (git remote get-url origin 2>$null).Trim()
} catch {
    $originUrl = ""
}

if ([string]::IsNullOrWhiteSpace($originUrl)) {
    git remote add origin $RepoUrl | Out-Null
    Write-Output "[OK] Added origin: $RepoUrl"
}
elseif ($originUrl -ne $RepoUrl) {
    git remote set-url origin $RepoUrl
    Write-Output "[OK] Updated origin -> $RepoUrl"
}
else {
    Write-Output "[OK] Origin already set: $originUrl"
}

git fetch --all --prune

$localExists = ((git branch --list $Branch).Trim() -ne "")
$remoteExists = ((git branch -r --list ("origin/" + $Branch)).Trim() -ne "")

if ($localExists) {
    git checkout $Branch
}
elseif ($remoteExists) {
    git checkout -b $Branch --track ("origin/" + $Branch)
}
else {
    git checkout -b $Branch
}

if ($remoteExists) {
    git pull --ff-only origin $Branch
}

if (-not $SkipRojoCheck) {
    if (Get-Command rojo -ErrorAction SilentlyContinue) {
        rojo sourcemap default.project.json -o sourcemap.json | Out-Null
        Write-Output "[OK] Rojo sourcemap generated."
    } else {
        Write-Output "[WARN] Rojo not found in PATH; skipped sourcemap check."
    }
}

Write-Output ""
Write-Output "Environment ready."
Write-Output "Next:"
Write-Output "  1) rojo serve"
Write-Output "  2) In Studio Rojo plugin: connect to localhost:34872 and open default.project.json"
