#!/usr/bin/env bash
# Offline check. Needs NO Genesys org, NO client ID and NO secret. Changes nothing in Genesys.
# Runs: function tests and zip, init and validate, the offline plan test (provider mocked), the repo safety check.
# It proves the design is well-formed. It does NOT prove Genesys will accept it: only a real apply does.
source "$(dirname "$0")/lib.sh"

say "Offline check (no org, no client ID, no secret)"

# Make sure nothing from an earlier session can be used by accident. This changes only this shell.
for v in GENESYSCLOUD_OAUTHCLIENT_ID GENESYSCLOUD_OAUTHCLIENT_SECRET; do
  if [ -n "${!v:-}" ]; then warn "$v was set in this shell. Clearing it for this shell only."; unset "$v"; fi
done
valid=" ap-northeast-1 ap-northeast-2 ap-northeast-3 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 dca eu-central-1 eu-central-2 eu-west-1 eu-west-2 eusc-de-east-1 me-central-1 mx-central-1 sa-east-1 tca us-east-1 us-east-2 us-west-2 "
if [[ "$valid" != *" ${GENESYSCLOUD_REGION:-none} "* ]]; then
  [ -n "${GENESYSCLOUD_REGION:-}" ] && warn "GENESYSCLOUD_REGION='${GENESYSCLOUD_REGION}' is not a region name. Using ap-southeast-2 for this run."
  export GENESYSCLOUD_REGION=ap-southeast-2
fi
ok "No credentials in use. Region name for validation: $GENESYSCLOUD_REGION"

pick_tf
command -v node >/dev/null 2>&1 || need node

PASS=0; SKIP=0
D="$(dirname "$0")"

say "Step 1 of 4: function tests and package"
bash "$D/01-package-function.sh" || die "Function tests or packaging failed."
PASS=$((PASS+1))

say "Step 2 of 4: initialise and validate"
bash "$D/02-init.sh" || die "Init or validate failed."
PASS=$((PASS+1))

say "Step 3 of 4: offline plan test (provider mocked)"
( cd "$TF_DIR" && $TF init -backend=false -input=false >/dev/null && $TF test ) || die "Offline plan test failed."
PASS=$((PASS+1))

say "Step 4 of 4: repo safety check"
PY=""
for c in python3 python py; do if command -v "$c" >/dev/null 2>&1 && "$c" --version >/dev/null 2>&1; then PY="$c"; break; fi; done
if [ -z "$PY" ]; then
  warn "Python is not installed, so the repo safety check was skipped. Install Python 3.12 and run this again."
  SKIP=$((SKIP+1))
else
  if ! "$PY" -c "import yaml, hcl2" >/dev/null 2>&1; then
    say "Installing the checker's two helper packages (pyyaml, python-hcl2)"
    "$PY" -m pip install --quiet pyyaml python-hcl2 || warn "pip could not install them. Try: $PY -m pip install --user pyyaml python-hcl2   (or use a virtual environment)"
  fi
  if "$PY" -c "import yaml, hcl2" >/dev/null 2>&1; then
    "$PY" "$REPO_ROOT/tools/check_repo.py" || die "Repo safety check failed. Fix the lines marked FAIL."
    PASS=$((PASS+1))
  else
    warn "The checker's helper packages are missing, so the repo safety check was skipped."
    SKIP=$((SKIP+1))
  fi
fi

echo
ok "Offline check finished. Passed: $PASS. Skipped: $SKIP. Failed: 0."
echo "Not run (these need a real Genesys org): preflight, plan against the org, apply, inventory, health check, drills, destroy."
