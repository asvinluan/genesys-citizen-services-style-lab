#!/usr/bin/env bash
# Shared helpers. Every other script starts with:  source "$(dirname "$0")/lib.sh"
# Not run on its own.

set -euo pipefail

# Where the repo is, wherever you run the script from.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TF_DIR="$REPO_ROOT/terraform"
# shellcheck disable=SC2034  # used by the scripts that source this file
FUNCTION_DIR="$TF_DIR/function-actions/normalise-reference"

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  OK  \033[0m%s\n' "$*"; }
warn() { printf '\033[1;33m WARN \033[0m%s\n' "$*"; }
die()  { printf '\033[1;31m FAIL \033[0m%s\n' "$*" >&2; exit 1; }

# Use OpenTofu if it is installed, otherwise Terraform.
pick_tf() {
  if command -v tofu >/dev/null 2>&1; then TF=tofu
  elif command -v terraform >/dev/null 2>&1; then TF=terraform
  else die "Neither tofu nor terraform is installed. On Windows run this in PowerShell: winget install --id OpenTofu.Tofu -e  then open a new window. Steps: docs/RUNBOOK-OFFLINE-BASH.md step 1."
  fi
  export TF
}

# The Genesys domain for each region. Sydney is the default for this lab.
genesys_domain() {
  case "${GENESYSCLOUD_REGION:-ap-southeast-2}" in
    ap-southeast-2) echo "mypurecloud.com.au" ;;
    ap-southeast-1) echo "apse1.pure.cloud" ;;
    ap-northeast-1) echo "mypurecloud.jp" ;;
    ap-northeast-2) echo "apne2.pure.cloud" ;;
    ap-south-1)     echo "aps1.pure.cloud" ;;
    us-east-1)      echo "mypurecloud.com" ;;
    us-west-2)      echo "usw2.pure.cloud" ;;
    ca-central-1)   echo "cac1.pure.cloud" ;;
    sa-east-1)      echo "sae1.pure.cloud" ;;
    eu-west-1)      echo "mypurecloud.ie" ;;
    eu-west-2)      echo "euw2.pure.cloud" ;;
    eu-central-1)   echo "mypurecloud.de" ;;
    *) die "Region '${GENESYSCLOUD_REGION}' is not in lib.sh. Use the region NAME (for example us-west-2), not the web address (usw2.pure.cloud). Add new ones to genesys_domain()." ;;
  esac
}

# Stops with a plain message if the three secrets are not set. Never prints the secret.
require_credentials() {
  : "${GENESYSCLOUD_OAUTHCLIENT_ID:?Set GENESYSCLOUD_OAUTHCLIENT_ID. See docs/RUNBOOK-BASH.md step 3.}"
  : "${GENESYSCLOUD_OAUTHCLIENT_SECRET:?Set GENESYSCLOUD_OAUTHCLIENT_SECRET. See docs/RUNBOOK-BASH.md step 3.}"
  export GENESYSCLOUD_REGION="${GENESYSCLOUD_REGION:-ap-southeast-2}"
}

# GENESYS_LOGIN_BASE and GENESYS_API_BASE exist only so the scripts can be tested against a local mock server.
# Leave them unset in real use.
# Gets a short-lived access token with the client-credentials grant.
# The token goes in a variable, never in a file and never on screen.
get_token() {
  require_credentials
  local domain resp; domain="$(genesys_domain)"
  # The credentials go to curl on stdin, not on the command line, so they never show in a process list.
  resp="$(printf 'user = "%s:%s"\n' "${GENESYSCLOUD_OAUTHCLIENT_ID}" "${GENESYSCLOUD_OAUTHCLIENT_SECRET}" |
    curl -sS --fail -K - \
      -d grant_type=client_credentials \
      "${GENESYS_LOGIN_BASE:-https://login.${domain}}/oauth/token" 2>/dev/null)" ||
    die "Could not get a token. Check the client ID, secret and region."
  TOKEN="$(printf '%s' "$resp" | jq -r '.access_token // empty')"
  [ -n "$TOKEN" ] || die "Could not get a token. Check the client ID, secret and region."
  export TOKEN
}

# api_get /api/v2/routing/queues?pageSize=1
api_get() {
  local domain; domain="$(genesys_domain)"
  curl -sS --fail-with-body -H "Authorization: Bearer ${TOKEN}" "${GENESYS_API_BASE:-https://api.${domain}}$1"
}

need() {
  command -v "$1" >/dev/null 2>&1 && return 0
  local hint
  case "$1" in
    jq)             hint="winget install --id jqlang.jq -e" ;;
    node)           hint="winget install --id OpenJS.NodeJS.LTS -e" ;;
    tofu)           hint="winget install --id OpenTofu.Tofu -e" ;;
    git)            hint="winget install --id Git.Git -e" ;;
    python|python3) hint="winget install --id Python.Python.3.12 -e" ;;
    *)              hint="winget search $1" ;;
  esac
  die "'$1' is not installed, or this window cannot see it. On Windows run this in PowerShell: $hint  then close this window and open a new one. On Linux or macOS use your package manager. Steps: docs/RUNBOOK-OFFLINE-BASH.md step 1."
}
