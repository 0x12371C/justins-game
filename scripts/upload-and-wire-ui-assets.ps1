param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$ApiKey = $env:ROBLOX_OPEN_CLOUD_API_KEY,
    [ValidateSet("user", "group")]
    [string]$CreatorType = "user",
    [string]$CreatorId,
    [string]$TopTooltipPath,
    [string]$BottomTooltipPath,
    [string]$EmeraldIconPath,
    [string]$PurpleGemIconPath,
    [string]$CookieFilePath = "$env:LOCALAPPDATA\Roblox\LocalStorage\RobloxCookies.dat",
    [string]$AppStoragePath = "$env:LOCALAPPDATA\Roblox\LocalStorage\appStorage.json",
    [int]$PollIntervalSeconds = 2,
    [int]$TimeoutSeconds = 240,
    [switch]$SkipSync,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

try { Add-Type -AssemblyName System.Security } catch { }
try { Add-Type -AssemblyName System.Net.Http } catch { }

function Normalize-AssetId {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    $trimmed = $Value.Trim()
    if ($trimmed -match '^rbxassetid://(\d+)$') {
        return "rbxassetid://$($Matches[1])"
    }

    if ($trimmed -match '^(\d+)$') {
        return "rbxassetid://$($Matches[1])"
    }

    if ($trimmed -match '(\d{6,})') {
        return "rbxassetid://$($Matches[1])"
    }

    throw "Invalid asset ID format: $Value"
}

function Get-MimeType {
    param([string]$Path)

    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        ".png" { return "image/png" }
        ".jpg" { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        ".webp" { return "image/webp" }
        ".bmp" { return "image/bmp" }
        default { return "application/octet-stream" }
    }
}

function Read-JsonObject {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $null
    }

    $raw = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    return $raw | ConvertFrom-Json
}

function Resolve-ExistingIds {
    param([string]$ManifestPath)

    $obj = Read-JsonObject -Path $ManifestPath
    $ids = @{
        topTooltip = ""
        bottomTooltip = ""
        emeraldIcon = ""
        purpleGemIcon = ""
    }

    if ($null -ne $obj) {
        foreach ($key in @($ids.Keys)) {
            if ($null -ne $obj.$key) {
                $ids[$key] = Normalize-AssetId -Value ([string]$obj.$key)
            }
        }
    }

    return $ids
}

function Resolve-UploadPath {
    param(
        [string]$PathValue,
        [string]$ProjectRoot,
        [string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $null
    }

    $candidate = $PathValue
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $candidate = Join-Path $ProjectRoot $candidate
    }

    if (-not (Test-Path $candidate)) {
        throw "File not found for ${Label}: $candidate"
    }

    return (Resolve-Path $candidate).Path
}

function Resolve-DefaultCreatorId {
    param([string]$AppStoragePath)

    $obj = Read-JsonObject -Path $AppStoragePath
    if ($null -eq $obj) {
        return $null
    }

    if ($null -ne $obj.UserId) {
        $candidate = [string]$obj.UserId
        if ($candidate -match '^\d+$') {
            return $candidate
        }
    }

    return $null
}

function Get-RoblosecurityCookie {
    param([string]$CookieFilePath)

    if (-not (Test-Path $CookieFilePath)) {
        return $null
    }

    $cookieBlob = Get-Content -Path $CookieFilePath -Raw | ConvertFrom-Json
    if ($null -eq $cookieBlob.CookiesData) {
        return $null
    }

    $encrypted = [Convert]::FromBase64String([string]$cookieBlob.CookiesData)
    $plain = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $encrypted,
        $null,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )

    $decoded = [System.Text.Encoding]::UTF8.GetString($plain)
    $match = [regex]::Match($decoded, '\.ROBLOSECURITY\t(?<value>[^;]+)')
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups["value"].Value
}

function Build-CreatorObject {
    param(
        [string]$Type,
        [string]$Id
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        throw "CreatorId is required."
    }

    if ($Id -notmatch '^\d+$') {
        throw "CreatorId must be numeric. Received: $Id"
    }

    if ($Type -eq "group") {
        return @{ groupId = "$Id" }
    }

    return @{ userId = "$Id" }
}

function New-OpenCloudClient {
    param([string]$ApiKey)

    $client = New-Object System.Net.Http.HttpClient
    $client.DefaultRequestHeaders.Add("x-api-key", $ApiKey)
    return $client
}

function New-UserAuthClient {
    param([string]$Roblosecurity)

    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.UseCookies = $true
    $handler.CookieContainer = New-Object System.Net.CookieContainer

    $cookie = New-Object System.Net.Cookie(".ROBLOSECURITY", $Roblosecurity, "/", ".roblox.com")
    $handler.CookieContainer.Add($cookie)

    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.DefaultRequestHeaders.Add("User-Agent", "Roblox/WinInet")

    return @{
        Client = $client
        Handler = $handler
    }
}

function New-MultipartPayload {
    param(
        [string]$RequestJson,
        [string]$FilePath
    )

    $multipart = New-Object System.Net.Http.MultipartFormDataContent

    $requestContent = New-Object System.Net.Http.StringContent(
        $RequestJson,
        [System.Text.Encoding]::UTF8,
        "application/json"
    )
    $multipart.Add($requestContent, "request")

    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    $fileContent = New-Object System.Net.Http.ByteArrayContent -ArgumentList (, $bytes)
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse((Get-MimeType -Path $FilePath))
    $multipart.Add($fileContent, "fileContent", [System.IO.Path]::GetFileName($FilePath))

    return @{
        Multipart = $multipart
        RequestContent = $requestContent
        FileContent = $fileContent
    }
}

function Invoke-UploadWithCsrf {
    param(
        $Client,
        [string]$Uri,
        [string]$RequestJson,
        [string]$FilePath
    )

    $payload = New-MultipartPayload -RequestJson $RequestJson -FilePath $FilePath
    try {
        $response = $Client.PostAsync($Uri, $payload.Multipart).Result
        $body = $response.Content.ReadAsStringAsync().Result
    }
    finally {
        $payload.Multipart.Dispose()
        $payload.RequestContent.Dispose()
        $payload.FileContent.Dispose()
    }

    if (
        -not $response.IsSuccessStatusCode -and
        $response.StatusCode -eq [System.Net.HttpStatusCode]::Forbidden -and
        $response.Headers.Contains("x-csrf-token")
    ) {
        $token = ($response.Headers.GetValues("x-csrf-token") | Select-Object -First 1)
        $Client.DefaultRequestHeaders.Remove("x-csrf-token") | Out-Null
        $Client.DefaultRequestHeaders.Add("x-csrf-token", $token)

        $payload = New-MultipartPayload -RequestJson $RequestJson -FilePath $FilePath
        try {
            $response = $Client.PostAsync($Uri, $payload.Multipart).Result
            $body = $response.Content.ReadAsStringAsync().Result
        }
        finally {
            $payload.Multipart.Dispose()
            $payload.RequestContent.Dispose()
            $payload.FileContent.Dispose()
        }
    }

    if (-not $response.IsSuccessStatusCode) {
        throw "Upload failed ($([int]$response.StatusCode)) at '$Uri': $body"
    }

    return $body
}

function Upload-ImageAssetOpenCloud {
    param(
        $Client,
        [hashtable]$Creator,
        [string]$FilePath,
        [string]$DisplayName,
        [string]$Description
    )

    $requestObject = @{
        assetType = "Image"
        displayName = $DisplayName
        description = $Description
        creationContext = @{ creator = $Creator }
    }

    $requestJson = $requestObject | ConvertTo-Json -Compress -Depth 6
    $payload = New-MultipartPayload -RequestJson $requestJson -FilePath $FilePath

    try {
        $response = $Client.PostAsync("https://apis.roblox.com/assets/v1/assets", $payload.Multipart).Result
        $body = $response.Content.ReadAsStringAsync().Result
    }
    finally {
        $payload.Multipart.Dispose()
        $payload.RequestContent.Dispose()
        $payload.FileContent.Dispose()
    }

    if (-not $response.IsSuccessStatusCode) {
        throw "Open Cloud upload failed ($([int]$response.StatusCode)) for '$DisplayName': $body"
    }

    $parsed = $body | ConvertFrom-Json
    $operationPath = [string]$parsed.path
    if ([string]::IsNullOrWhiteSpace($operationPath)) {
        throw "Open Cloud upload returned no operation path for '$DisplayName': $body"
    }

    return $operationPath
}

function Upload-ImageAssetUserAuth {
    param(
        $Client,
        [hashtable]$Creator,
        [string]$FilePath,
        [string]$DisplayName,
        [string]$Description
    )

    $requestObject = @{
        assetType = "Image"
        displayName = $DisplayName
        description = $Description
        creationContext = @{ creator = $Creator }
    }

    $requestJson = $requestObject | ConvertTo-Json -Compress -Depth 6
    $body = Invoke-UploadWithCsrf -Client $Client -Uri "https://apis.roblox.com/assets/user-auth/v1/assets" -RequestJson $requestJson -FilePath $FilePath

    $parsed = $body | ConvertFrom-Json
    $operationPath = [string]$parsed.path
    if ([string]::IsNullOrWhiteSpace($operationPath)) {
        throw "User-auth upload returned no operation path for '$DisplayName': $body"
    }

    return $operationPath
}

function Wait-ForAssetId {
    param(
        $Client,
        [string]$OperationPath,
        [string]$OperationBaseUri,
        [int]$PollSeconds,
        [int]$TimeoutSeconds
    )

    $op = $OperationPath.Trim()
    if ($op.StartsWith("/")) {
        $op = $op.TrimStart("/")
    }
    if (-not $op.StartsWith("operations/")) {
        $op = "operations/$op"
    }

    $uri = "$OperationBaseUri/$op"
    $start = Get-Date

    while ($true) {
        $response = $Client.GetAsync($uri).Result
        $body = $response.Content.ReadAsStringAsync().Result

        if (-not $response.IsSuccessStatusCode) {
            throw "Operation polling failed ($([int]$response.StatusCode)) on '$op': $body"
        }

        $payload = $body | ConvertFrom-Json
        if ($payload.done -eq $true) {
            if ($null -ne $payload.error) {
                $errorJson = ($payload.error | ConvertTo-Json -Compress -Depth 10)
                throw "Asset operation failed for '$op': $errorJson"
            }

            $assetId = $null
            if ($null -ne $payload.response -and $null -ne $payload.response.assetId) {
                $assetId = [string]$payload.response.assetId
            }

            if ([string]::IsNullOrWhiteSpace($assetId) -and $body -match '"assetId"\s*:\s*"?(?<id>\d+)"?') {
                $assetId = $Matches["id"]
            }

            if ([string]::IsNullOrWhiteSpace($assetId)) {
                throw "Operation completed without assetId for '$op': $body"
            }

            return "rbxassetid://$assetId"
        }

        if (((Get-Date) - $start).TotalSeconds -gt $TimeoutSeconds) {
            throw "Timed out waiting for '$op' after $TimeoutSeconds seconds."
        }

        Start-Sleep -Seconds $PollSeconds
    }
}

function Resolve-AuthenticatedUserId {
    param($Client)

    $response = $Client.GetAsync("https://users.roblox.com/v1/users/authenticated").Result
    $body = $response.Content.ReadAsStringAsync().Result

    if (-not $response.IsSuccessStatusCode) {
        throw "Failed to resolve authenticated user id ($([int]$response.StatusCode)): $body"
    }

    $obj = $body | ConvertFrom-Json
    if ($null -eq $obj.id) {
        throw "Authenticated user response missing id: $body"
    }

    return [string]$obj.id
}

function Find-TooltipCandidate {
    param(
        [string]$ProjectRoot,
        [ValidateSet("top", "bottom")]
        [string]$Slot
    )

    $images = Get-ChildItem -Path $ProjectRoot -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -match '^(\.png|\.jpg|\.jpeg|\.webp|\.bmp)$' } |
        Where-Object { $_.Name -notmatch 'emerald|diamond|gem|cluuster|cluster|reference|concept' }

    if ($Slot -eq "top") {
        $strong = $images | Where-Object { $_.Name -match 'tooltip|top|teal|green|mint|currency' } | Select-Object -First 1
        if ($strong) { return $strong.FullName }
    }
    else {
        $strong = $images | Where-Object { $_.Name -match 'tooltip|bottom|purple|violet|gem' } | Select-Object -First 1
        if ($strong) { return $strong.FullName }
    }

    return $null
}

$manifestPath = Join-Path $ProjectRoot "assets\ui-asset-ids.json"
$syncScriptPath = Join-Path $ProjectRoot "scripts\sync-ui-asset-ids.ps1"

if (-not (Test-Path $syncScriptPath)) {
    throw "Missing sync script: $syncScriptPath"
}

$resolvedIds = Resolve-ExistingIds -ManifestPath $manifestPath

if (-not $PSBoundParameters.ContainsKey("TopTooltipPath")) {
    $TopTooltipPath = Find-TooltipCandidate -ProjectRoot $ProjectRoot -Slot "top"
}

if (-not $PSBoundParameters.ContainsKey("BottomTooltipPath")) {
    $BottomTooltipPath = Find-TooltipCandidate -ProjectRoot $ProjectRoot -Slot "bottom"
}

if (-not $PSBoundParameters.ContainsKey("EmeraldIconPath")) {
    $defaultEmerald = Join-Path $ProjectRoot "emeraldcluuster.png"
    if (Test-Path $defaultEmerald) {
        $EmeraldIconPath = $defaultEmerald
    }
}

if (-not $PSBoundParameters.ContainsKey("PurpleGemIconPath")) {
    $defaultPurple = Join-Path $ProjectRoot "purplediamond.png"
    if (Test-Path $defaultPurple) {
        $PurpleGemIconPath = $defaultPurple
    }
}

$uploads = @(
    [PSCustomObject]@{ Key = "topTooltip"; Label = "Top Tooltip"; Path = (Resolve-UploadPath -PathValue $TopTooltipPath -ProjectRoot $ProjectRoot -Label "TopTooltipPath") }
    [PSCustomObject]@{ Key = "bottomTooltip"; Label = "Bottom Tooltip"; Path = (Resolve-UploadPath -PathValue $BottomTooltipPath -ProjectRoot $ProjectRoot -Label "BottomTooltipPath") }
    [PSCustomObject]@{ Key = "emeraldIcon"; Label = "Emerald Icon"; Path = (Resolve-UploadPath -PathValue $EmeraldIconPath -ProjectRoot $ProjectRoot -Label "EmeraldIconPath") }
    [PSCustomObject]@{ Key = "purpleGemIcon"; Label = "Purple Gem Icon"; Path = (Resolve-UploadPath -PathValue $PurpleGemIconPath -ProjectRoot $ProjectRoot -Label "PurpleGemIconPath") }
) | Where-Object { $null -ne $_.Path }

if ($uploads.Count -eq 0) {
    throw "No images selected for upload."
}

if ([string]::IsNullOrWhiteSpace($CreatorId)) {
    $CreatorId = Resolve-DefaultCreatorId -AppStoragePath $AppStoragePath
}

$authMode = if ([string]::IsNullOrWhiteSpace($ApiKey)) { "user_auth_cookie" } else { "open_cloud" }

Write-Output "[INFO] ProjectRoot: $ProjectRoot"
Write-Output "[INFO] Manifest: $manifestPath"
Write-Output "[INFO] Auth mode: $authMode"
Write-Output "[INFO] Upload queue:"
foreach ($u in $uploads) {
    Write-Output ("  - {0}: {1}" -f $u.Label, $u.Path)
}

if ($DryRun) {
    Write-Output "[DRY RUN] Skipped upload and sync."
    exit 0
}

$client = $null
$handler = $null
$creator = $null
$operationBaseUri = $null

try {
    if ($authMode -eq "open_cloud") {
        if ([string]::IsNullOrWhiteSpace($CreatorId)) {
            throw "CreatorId is required for Open Cloud mode."
        }

        $creator = Build-CreatorObject -Type $CreatorType -Id $CreatorId
        $client = New-OpenCloudClient -ApiKey $ApiKey
        $operationBaseUri = "https://apis.roblox.com/assets/v1"

        foreach ($upload in $uploads) {
            $displayName = "Frontier UI - $($upload.Label)"
            $description = "Auto-uploaded by upload-and-wire-ui-assets.ps1"
            Write-Output ("[UPLOAD] {0}" -f $displayName)

            $operationPath = Upload-ImageAssetOpenCloud -Client $client -Creator $creator -FilePath $upload.Path -DisplayName $displayName -Description $description
            Write-Output ("[POLL] {0}" -f $operationPath)

            $assetId = Wait-ForAssetId -Client $client -OperationPath $operationPath -OperationBaseUri $operationBaseUri -PollSeconds $PollIntervalSeconds -TimeoutSeconds $TimeoutSeconds
            $resolvedIds[$upload.Key] = $assetId

            Write-Output ("[OK] {0} -> {1}" -f $upload.Label, $assetId)
        }
    }
    else {
        $roblosecurity = Get-RoblosecurityCookie -CookieFilePath $CookieFilePath
        if ([string]::IsNullOrWhiteSpace($roblosecurity)) {
            throw "Could not read .ROBLOSECURITY cookie from $CookieFilePath"
        }

        $userAuth = New-UserAuthClient -Roblosecurity $roblosecurity
        $client = $userAuth.Client
        $handler = $userAuth.Handler

        if ([string]::IsNullOrWhiteSpace($CreatorId)) {
            $CreatorId = Resolve-AuthenticatedUserId -Client $client
        }

        $creator = Build-CreatorObject -Type $CreatorType -Id $CreatorId
        $operationBaseUri = "https://apis.roblox.com/assets/user-auth/v1"

        foreach ($upload in $uploads) {
            $displayName = "Frontier UI - $($upload.Label)"
            $description = "Auto-uploaded by upload-and-wire-ui-assets.ps1"
            Write-Output ("[UPLOAD] {0}" -f $displayName)

            $operationPath = Upload-ImageAssetUserAuth -Client $client -Creator $creator -FilePath $upload.Path -DisplayName $displayName -Description $description
            Write-Output ("[POLL] {0}" -f $operationPath)

            $assetId = Wait-ForAssetId -Client $client -OperationPath $operationPath -OperationBaseUri $operationBaseUri -PollSeconds $PollIntervalSeconds -TimeoutSeconds $TimeoutSeconds
            $resolvedIds[$upload.Key] = $assetId

            Write-Output ("[OK] {0} -> {1}" -f $upload.Label, $assetId)
        }
    }
}
finally {
    if ($null -ne $client) {
        $client.Dispose()
    }
    if ($null -ne $handler) {
        $handler.Dispose()
    }
}

if (-not $SkipSync) {
    $syncArgs = @{
        ProjectRoot = $ProjectRoot
        TopTooltip = [string]$resolvedIds.topTooltip
        BottomTooltip = [string]$resolvedIds.bottomTooltip
        EmeraldIcon = [string]$resolvedIds.emeraldIcon
        PurpleGemIcon = [string]$resolvedIds.purpleGemIcon
    }

    & $syncScriptPath @syncArgs

    if (-not $?) {
        throw "sync-ui-asset-ids.ps1 failed."
    }
}

Write-Output "[DONE] Upload + wiring complete."
