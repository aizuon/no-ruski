<#
.SYNOPSIS
  Packages the NoRuski addon into a CurseForge-ready zip.

.DESCRIPTION
  Produces dist/NoRuski-<version>.zip containing a top-level NoRuski/ folder
  (the layout CurseForge and the WoW client both expect). The version is read
  from the ## Version line in NoRuski.toc.
#>

$ErrorActionPreference = "Stop"

$root  = Split-Path -Parent $PSScriptRoot
$toc   = Join-Path $root "NoRuski.toc"
$dist  = Join-Path $root "dist"
$stage = Join-Path $dist "NoRuski"

$version = (Select-String -Path $toc -Pattern '^##\s*Version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
if (-not $version) { $version = "0.0.0" }

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null

Copy-Item (Join-Path $root "NoRuski.toc") $stage
Copy-Item (Join-Path $root "NoRuski.lua") $stage
Copy-Item (Join-Path $root "README.md")   $stage
Copy-Item (Join-Path $root "LICENSE")     $stage

$zip = Join-Path $dist "NoRuski-$version.zip"
Compress-Archive -Path $stage -DestinationPath $zip -Force

Write-Host "Built $zip"
