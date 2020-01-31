#!/usr/bin/env powershell

#Requires -Version 5

$ErrorActionPreference="stop"

# Import shared functions
. $PSScriptRoot\shared.ps1

# We have to do this because everything that comes from vault is quoted on windows.
$Rawtoken=$Env:PIPELINE_HAB_AUTH_TOKEN
$Env:HAB_AUTH_TOKEN=$Rawtoken.Replace("`"","")

$Env:buildkiteAgentToken = $Env:BUILDKITE_AGENT_ACCESS_TOKEN

$Env:HAB_BLDR_URL=$Env:PIPELINE_HAB_BLDR_URL
$Env:HAB_PACKAGE_TARGET=$Env:BUILD_PKG_TARGET

Install-BuildkiteAgent

# Install jq if it doesn't exist
choco install jq -y | Out-Null

# For viewability
$Channel = "habitat-release-$Env:BUILDKITE_BUILD_ID"
Write-Host "--- Channel: $Channel - bldr url: $Env:HAB_BLDR_URL"

$baseHabExe=Install-LatestHabitat

# Get keys
Write-Host "--- :key: Downloading '$Env:HAB_ORIGIN' public keys from Builder"
Invoke-Expression "$baseHabExe origin key download $Env:HAB_ORIGIN"
Write-Host "--- :closed_lock_with_key: Downloading latest '$Env:HAB_ORIGIN' secret key from Builder"
Invoke-Expression "$baseHabExe origin key download $Env:HAB_ORIGIN --auth $Env:HAB_AUTH_TOKEN --secret"
$Env:HAB_CACHE_KEY_PATH = "C:\hab\cache\keys"

# Download builder code and build
$builderSHA=Get-BuilderSHAMetadata
Write-Host "--- Downloading Builder code @ $builderSHA"
# I doubt we're ever going to have a directory called "builder" in
# this repository, but better safe than sorry.
$cloneDirectory="builder-" + (Get-Date -UFormat "%Y%m%d%H%M%S")
Invoke-Expression "git clone https://github.com/habitat-sh/builder $cloneDirectory"
cd "$cloneDirectory"
Invoke-Expression "git checkout $builderSHA"

# Run a build!
Write-Host "--- :habicat: Building builder-worker"

# Note: HAB_BLDR_CHANNEL *must* be set for the following `hab pkg
# build` command! There isn't currently a CLI option to set that, and
# we must ensure that we're pulling dependencies from our build
# channel when applicable.
$Env:HAB_BLDR_CHANNEL="$Channel"
Invoke-Expression "$baseHabExe pkg build components\builder-worker"
. results\last_build.ps1

Write-Host "--- :habicat: Uploading $pkg_ident to $env:HAB_BLDR_URL in the '$Channel' channel"
Invoke-Expression "$baseHabExe pkg upload results\$pkg_artifact --channel=$Channel --no-build"
Set-TargetMetadata $pkg_ident

Invoke-Expression "buildkite-agent annotate --append --context 'release-manifest' '<br>* ${pkg_ident} (x86_64-windows)'"

exit $LASTEXITCODE
