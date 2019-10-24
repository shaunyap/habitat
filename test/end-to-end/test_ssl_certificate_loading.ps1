#!/bin/bash

$ErrorActionPreference="stop" 

Write-Host "--- Generating a signing key"
hab origin key generate "$env:HAB_ORIGIN"

Write-Host "--- Testing fresh install of Habitat can communicate with builder"

Describe "Fresh Install" {
    It "Doesn't have any ssl certificates cached"  {
       $certCache = Get-ChildItem c:\hab\cache\ssl | Measure-Object
       $certCache.count | Should -Be 0
    }

    It "Can install packages" {
       hab pkg install core/7zip
       $LASTEXITCODE | Should -Be 0
    }
}

Describe "Custom Certificates" {
    BeforeEach {
        Remove-Item c:\hab\cache\ssl -Recurse -Force 
    }

    It "Can install packages when an invalid certificate is present" {
        New-Item -Type Directory -Path c:\hab\cache\ssl
        New-Item -Type File -Path c:\hab\cache\ssl\invalid-certifcate.pem
        Add-Content -Path c:\hab\cache\ssl\invalid-certificate.pem "I AM NOT A CERTIFICATE" 

        hab pkg install core/nginx
        $LASTEXITCODE | Should -Be 0
    }

    It "Loads custom certificates" {
        New-Item -Type Directory -Path c:\hab\cache\ssl
        hab pkg install core/openssl
        hab pkg exec core/openssl openssl req -newkey rsa:2048 -batch -nodes -keyout key.pem -x509 -days 365 -out c:\hab\cache\ssl\custom-certificate.pem

        $env:RUST_LOG="debug"
        $output = hab pkg search core/7zip
        $output | Should -Contain "Processing cert file: c:\hab\cache\ssl\custom-certificate.pem"
  }
}
