# Offline check. Needs NO Genesys org, NO client ID and NO secret. Changes nothing in Genesys.
# Runs: function tests and zip, init and validate, the offline plan test (provider mocked), the repo safety check.
# It proves the design is well-formed. It does NOT prove Genesys will accept it: only a real apply does.
# Works in Windows PowerShell 5.1 and PowerShell 7.
. "$PSScriptRoot\lib.ps1"

Say "Offline check (no org, no client ID, no secret)"

# Make sure nothing from an earlier session can be used by accident. This changes only this window.
foreach ($v in 'GENESYSCLOUD_OAUTHCLIENT_ID', 'GENESYSCLOUD_OAUTHCLIENT_SECRET') {
    if (Test-Path "Env:$v") { Warn "$v was set in this window. Clearing it for this window only."; Remove-Item "Env:$v" }
}
$valid = @('ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','dca','eu-central-1','eu-central-2','eu-west-1','eu-west-2','eusc-de-east-1','me-central-1','mx-central-1','sa-east-1','tca','us-east-1','us-east-2','us-west-2')
if ($valid -notcontains $env:GENESYSCLOUD_REGION) {
    if ($env:GENESYSCLOUD_REGION) { Warn "GENESYSCLOUD_REGION='$($env:GENESYSCLOUD_REGION)' is not a region name. Using ap-southeast-2 for this run." }
    $env:GENESYSCLOUD_REGION = 'ap-southeast-2'
}
Ok "No credentials in use. Region name for validation: $($env:GENESYSCLOUD_REGION)"

$tf = Get-TfCommand
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Fail "node is not installed or this window is older than the install. Close PowerShell, open it again, and rerun. See docs\RUNBOOK-OFFLINE-POWERSHELL.md step 1." }

$pass = 0; $skip = 0

Say "Step 1 of 4: function tests and package"
$global:LASTEXITCODE = 0
& (Join-Path $PSScriptRoot '01-package-function.ps1')
if ($LASTEXITCODE -ne 0) { Fail "Function tests or packaging failed." }
$pass++

Say "Step 2 of 4: initialise and validate"
$global:LASTEXITCODE = 0
& (Join-Path $PSScriptRoot '02-init.ps1')
if ($LASTEXITCODE -ne 0) { Fail "Init or validate failed." }
$pass++

Say "Step 3 of 4: offline plan test (provider mocked)"
Push-Location $script:TfDir
try {
    & $tf init -backend=false -input=false | Out-Null
    Assert-LastExit 'init'
    & $tf test
    Assert-LastExit 'offline plan test'
} finally { Pop-Location }
$pass++

Say "Step 4 of 4: repo safety check"
$py = $null
foreach ($c in 'python', 'py') {
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($cmd) {
        $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        & $c --version *> $null
        $okv = ($LASTEXITCODE -eq 0)
        $ErrorActionPreference = $prev
        if ($okv) { $py = $c; break }
    }
}
if (-not $py) {
    Warn "Python is not installed, so the repo safety check was skipped. Install Python 3.12 (winget install --id Python.Python.3.12 -e), reopen PowerShell, and run this again."
    $skip++
} else {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $py -c "import yaml, hcl2" *> $null
    $haveHelpers = ($LASTEXITCODE -eq 0)
    if (-not $haveHelpers) {
        Say "Installing the checker's two helper packages (pyyaml, python-hcl2)"
        & $py -m pip install --quiet pyyaml python-hcl2
        & $py -c "import yaml, hcl2" *> $null
        $haveHelpers = ($LASTEXITCODE -eq 0)
    }
    $ErrorActionPreference = $prev
    if ($haveHelpers) {
        & $py (Join-Path $script:RepoRoot 'tools\check_repo.py')
        if ($LASTEXITCODE -ne 0) { Fail "Repo safety check failed. Fix the lines marked FAIL." }
        $pass++
    } else {
        Warn "The checker's helper packages are missing, so the repo safety check was skipped. Try: $py -m pip install pyyaml python-hcl2"
        $skip++
    }
}

Write-Host ""
Ok "Offline check finished. Passed: $pass. Skipped: $skip. Failed: 0."
Write-Host "Not run (these need a real Genesys org): preflight, plan against the org, apply, inventory, health check, drills, destroy."
