# Step 2. Downloads the Genesys provider and checks the files are well-formed. Changes nothing in Genesys.
# If the saved provider checksums do not match this computer (common when the lock file was made on another
# operating system), it adds checksums for the usual platforms and tries once more. Only the lock file changes.
. "$PSScriptRoot\lib.ps1"
$tf = Get-TfCommand
Push-Location $script:TfDir
try {
    Say "Formatting check"
    & $tf fmt -check -recursive
    if ($LASTEXITCODE -ne 0) { Fail "Files are not formatted. Run: $tf fmt -recursive" }
    Ok "Formatting is clean"

    Say "Initialising (no remote state)"
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = (& $tf init -backend=false -input=false 2>&1 | Out-String)
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    Write-Host $out
    if ($code -ne 0) {
        if ($out -match 'checksums? previously recorded') {
            Warn "The saved provider checksums do not match this computer. Adding checksums for the usual platforms, then trying again."
            & $tf providers lock -platform=windows_amd64 -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64
            Assert-LastExit 'providers lock'
            & $tf init -backend=false -input=false
            Assert-LastExit 'init'
        } else {
            Fail "init failed. Read the error above."
        }
    }
    Say "Validating"
    # Validation reads the region setting. A web address such as usw2.pure.cloud is rejected; a region name is not.
    if (-not $env:GENESYSCLOUD_REGION) { $env:GENESYSCLOUD_REGION = 'ap-southeast-2' }
    & $tf validate
    Assert-LastExit 'validate'
    Ok "Configuration is valid"
} finally { Pop-Location }
