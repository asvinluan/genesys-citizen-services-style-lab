#!/usr/bin/env bash
# Step 2. Downloads the Genesys provider and checks the files are well-formed. Changes nothing in Genesys.
# If the saved provider checksums do not match this computer (common when the lock file was made on another
# operating system), it adds checksums for the usual platforms and tries once more. Only the lock file changes.
source "$(dirname "$0")/lib.sh"
pick_tf
cd "$TF_DIR"

say "Formatting check"
$TF fmt -check -recursive || die "Files are not formatted. Run: $TF fmt -recursive"
ok "Formatting is clean"

say "Initialising (no remote state)"
if out="$($TF init -backend=false -input=false 2>&1)"; then
  printf '%s\n' "$out"
else
  printf '%s\n' "$out"
  if printf '%s' "$out" | grep -qi "checksums previously recorded"; then
    warn "The saved provider checksums do not match this computer. Adding checksums for the usual platforms, then trying again."
    $TF providers lock -platform=windows_amd64 -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64 \
      || die "Could not update the lock file."
    $TF init -backend=false -input=false || die "init failed again."
  else
    die "init failed. Read the error above."
  fi
fi
say "Validating"
# Validation reads the region setting. A web address such as usw2.pure.cloud is rejected; a region name is not.
if [ -z "${GENESYSCLOUD_REGION:-}" ]; then export GENESYSCLOUD_REGION=ap-southeast-2; fi
$TF validate
ok "Configuration is valid"
