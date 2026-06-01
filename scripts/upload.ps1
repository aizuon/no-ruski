<#
.SYNOPSIS
  Uploads a packaged NoRuski zip to an EXISTING CurseForge project.

.DESCRIPTION
  Uses CurseForge's official upload API. You must first create the project
  manually at https://www.curseforge.com (the API cannot create new projects),
  then pass its numeric project ID here.

  The API token is read from the CF_API_TOKEN environment variable so it is
  never stored in the repository. Set it for the current session only, e.g.:

      $env:CF_API_TOKEN = "<your-token>"

.PARAMETER ProjectId
  Numeric CurseForge project ID (shown on the project page / dashboard).

.PARAMETER ZipPath
  Path to the packaged zip (defaults to the newest file in dist/).

.PARAMETER GameVersionId
  Optional CurseForge game-version ID. If omitted, the script lists the
  available IDs so you can pick the correct Midnight (12.0.5) one.

.EXAMPLE
  .\scripts\package.ps1
  $env:CF_API_TOKEN = "<token>"
  .\scripts\upload.ps1 -ProjectId 123456 -GameVersionId 12345
#>

param(
    [Parameter(Mandatory = $true)] [int] $ProjectId,
    [string] $ZipPath,
    [int] $GameVersionId,
    [ValidateSet("alpha", "beta", "release")] [string] $ReleaseType = "release",
    [string] $Changelog = "See README / commit history."
)

$ErrorActionPreference = "Stop"

$token = $env:CF_API_TOKEN
if (-not $token) {
    throw "CF_API_TOKEN environment variable is not set. Set it for this session: `$env:CF_API_TOKEN = '<token>'"
}

if (-not $ZipPath) {
    $dist = Join-Path (Split-Path -Parent $PSScriptRoot) "dist"
    $ZipPath = (Get-ChildItem $dist -Filter *.zip | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}
if (-not (Test-Path $ZipPath)) { throw "Zip not found: $ZipPath. Run scripts/package.ps1 first." }

$headers = @{ "X-Api-Token" = $token }

if (-not $GameVersionId) {
    Write-Host "No -GameVersionId provided. Available WoW game versions (pick the Midnight 12.0.5 id):`n"
    $versions = Invoke-RestMethod -Uri "https://wow.curseforge.com/api/game/versions" -Headers $headers
    $versions | Where-Object { $_.name -like "12.*" } | Sort-Object name |
        Format-Table id, name, slug -AutoSize
    Write-Host "`nRe-run with -GameVersionId <id>."
    return
}

$metadata = @{
    changelog     = $Changelog
    changelogType = "text"
    releaseType   = $ReleaseType
    gameVersions  = @($GameVersionId)
} | ConvertTo-Json -Compress

$form = @{
    metadata = $metadata
    file     = Get-Item $ZipPath
}

$uri = "https://wow.curseforge.com/api/projects/$ProjectId/upload-file"
$resp = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Form $form
Write-Host "Uploaded. CurseForge file id: $($resp.id)"
