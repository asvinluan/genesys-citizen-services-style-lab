#!/usr/bin/env bash
# Step 1. Tests the claim-number function, then zips it. Changes only the dist folder.
source "$(dirname "$0")/lib.sh"
need node

say "Running the function tests"
( cd "$FUNCTION_DIR" && node --test )
ok "Tests passed"

say "Building the zip"
mkdir -p "$FUNCTION_DIR/dist"
rm -f "$FUNCTION_DIR/dist/normalise-reference.zip"
if command -v zip >/dev/null 2>&1; then
  ( cd "$FUNCTION_DIR" && zip -q -X dist/normalise-reference.zip index.js )
else
  PYBIN=""
  for c in python3 python py; do
    if command -v "$c" >/dev/null 2>&1 && "$c" --version >/dev/null 2>&1; then PYBIN="$c"; break; fi
  done
  [ -n "$PYBIN" ] || die "Neither zip nor Python is installed. Install Python (on Windows: winget install --id Python.Python.3.12 -e, then open a new window)."
  ( cd "$FUNCTION_DIR" && "$PYBIN" -m zipfile -c dist/normalise-reference.zip index.js )
fi
ok "Built $FUNCTION_DIR/dist/normalise-reference.zip"
