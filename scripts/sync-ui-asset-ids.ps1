param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$TopTooltip,
    [string]$BottomTooltip,
    [string]$EmeraldIcon,
    [string]$PurpleGemIcon,
    [string]$ManifestPath,
    [switch]$FromManifestOnly
)

$ErrorActionPreference = "Stop"

function Normalize-AssetId {
    param(
        [string]$Value,
        [string]$FieldName
    )

    if ($null -eq $Value) {
        return ""
    }

    $trimmed = $Value.Trim()
    if ($trimmed -eq "") {
        return ""
    }

    if ($trimmed -match '^rbxassetid://(\d+)$') {
        return "rbxassetid://$($Matches[1])"
    }

    if ($trimmed -match '^\d+$') {
        return "rbxassetid://$trimmed"
    }

    if ($trimmed -match '(\d{6,})') {
        return "rbxassetid://$($Matches[1])"
    }

    throw "Invalid asset ID for '$FieldName': $Value"
}

function Read-Manifest {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @{}
    }

    $raw = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @{}
    }

    $obj = $raw | ConvertFrom-Json
    $result = @{}
    foreach ($key in @("topTooltip", "bottomTooltip", "emeraldIcon", "purpleGemIcon")) {
        if ($null -ne $obj.$key) {
            $result[$key] = [string]$obj.$key
        }
    }
    return $result
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Update-LuaAssetIds {
    param(
        [string]$Path,
        [hashtable]$Ids
    )

    if (-not (Test-Path $Path)) {
        return $false
    }

    $lua = Get-Content -Path $Path -Raw
    $pattern = 'local ASSET_IDS = \{[\s\S]*?\n\}'
    if ($lua -notmatch $pattern) {
        throw "Could not find ASSET_IDS block in: $Path"
    }

    $replacement = @"
local ASSET_IDS = {
	topTooltip = "$($Ids.topTooltip)", -- e.g. "rbxassetid://1234567890"
	bottomTooltip = "$($Ids.bottomTooltip)",
	emeraldIcon = "$($Ids.emeraldIcon)",
	purpleGemIcon = "$($Ids.purpleGemIcon)",
}
"@

    $updated = [System.Text.RegularExpressions.Regex]::Replace($lua, $pattern, $replacement, 1)
    Write-Utf8NoBom -Path $Path -Content $updated
    return $true
}

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $ProjectRoot "assets\ui-asset-ids.json"
}

$manifestValues = Read-Manifest -Path $ManifestPath

$incoming = @{
    topTooltip = $TopTooltip
    bottomTooltip = $BottomTooltip
    emeraldIcon = $EmeraldIcon
    purpleGemIcon = $PurpleGemIcon
}

$provided = @{
    topTooltip = $PSBoundParameters.ContainsKey("TopTooltip")
    bottomTooltip = $PSBoundParameters.ContainsKey("BottomTooltip")
    emeraldIcon = $PSBoundParameters.ContainsKey("EmeraldIcon")
    purpleGemIcon = $PSBoundParameters.ContainsKey("PurpleGemIcon")
}

$resolved = @{}
foreach ($key in @("topTooltip", "bottomTooltip", "emeraldIcon", "purpleGemIcon")) {
    if (-not $FromManifestOnly -and $provided[$key]) {
        $resolved[$key] = $incoming[$key]
    }
    elseif ($manifestValues.ContainsKey($key)) {
        $resolved[$key] = $manifestValues[$key]
    }
    else {
        $resolved[$key] = ""
    }

    $resolved[$key] = Normalize-AssetId -Value $resolved[$key] -FieldName $key
}

$manifestObject = [ordered]@{
    topTooltip = $resolved.topTooltip
    bottomTooltip = $resolved.bottomTooltip
    emeraldIcon = $resolved.emeraldIcon
    purpleGemIcon = $resolved.purpleGemIcon
}

$manifestDir = Split-Path -Path $ManifestPath -Parent
if (-not (Test-Path $manifestDir)) {
    New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null
}

$manifestJson = ($manifestObject | ConvertTo-Json) + [Environment]::NewLine
Write-Utf8NoBom -Path $ManifestPath -Content $manifestJson

$targets = @(
    (Join-Path $ProjectRoot "src\client\FrontierCurrencyUi.client.lua"),
    (Join-Path $ProjectRoot "FrontierCurrencyUi.client.lua")
)

$updatedTargets = @()
foreach ($target in $targets) {
    if (Update-LuaAssetIds -Path $target -Ids $resolved) {
        $updatedTargets += $target
    }
}

if ($updatedTargets.Count -eq 0) {
    throw "No target UI script found under $ProjectRoot"
}

Write-Output "[OK] Updated ASSET_IDS in:"
foreach ($target in $updatedTargets) {
    Write-Output ("  - " + $target)
}

Write-Output "[OK] Saved manifest:"
Write-Output ("  - " + $ManifestPath)

Write-Output "[ASSET_IDS]"
Write-Output ("  topTooltip   = " + $resolved.topTooltip)
Write-Output ("  bottomTooltip= " + $resolved.bottomTooltip)
Write-Output ("  emeraldIcon  = " + $resolved.emeraldIcon)
Write-Output ("  purpleGemIcon= " + $resolved.purpleGemIcon)
