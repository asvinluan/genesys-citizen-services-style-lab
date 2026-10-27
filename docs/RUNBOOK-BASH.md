# Runbook: Bash (Linux, macOS, WSL, CI)

Every command to build the Citizen Services-style lab Genesys Cloud lab from a Bash shell. One action per step. After each step there is **You should see**.

If you are on Windows, use `RUNBOOK-POWERSHELL.md` unless you have WSL (Windows Subsystem for Linux). Git Bash alone is not enough: it lacks `jq`.

**Before you start:** read Part 1 and 2 of `BUILD-MANUAL.md` (a lab org and an OAuth client). **Never run this against a customer's org.**

> **No Genesys org, client ID or secret yet?** Use `RUNBOOK-OFFLINE-BASH.md`. It runs everything that needs no org. Come back to this runbook when you have a lab org and an OAuth client.

> **How to paste.** Paste one block at a time and read the result before the next one. Never paste a result back in as a command. If a command fails, copy only the command and the error when you ask for help.

---

## Step 1. Install the tools (once)

### Windows

`apt-get` and `sudo` are Linux commands and do not exist on Windows (`Sudo is disabled on this machine` is Windows telling you so). You do not need them. Install the tools **from PowerShell** with winget (skip any line you already did):

```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e
winget install --id OpenTofu.Tofu -e
winget install --id Python.Python.3.12 -e
winget install --id jqlang.jq -e
```

Type each line exactly: two dashes before `id`, none before the package name. Then **close the bash window and open a new one** so it sees the tools.

**Which bash window?** Any of them works: Git Bash, the MSYS2 window (`UCRT64`) or WSL. What matters is that the check below prints a version for every tool. In an MSYS2 or Git Bash window the paths look like `/c/Users/YOU/...`.

### Linux, macOS, WSL

**Ubuntu, Debian, or WSL:**

```bash
sudo apt-get update
sudo apt-get install -y git curl jq zip unzip python3 python3-pip python3-venv
# Node.js 22: use your preferred method, for example NodeSource or nvm.
# OpenTofu: https://opentofu.org/docs/intro/install/  (or HashiCorp Terraform)
```

**macOS (Homebrew):**

```bash
brew install git jq node opentofu python
```

Check (all platforms):

```bash
git --version; curl --version | head -1; jq --version; node --version; tofu version; python --version
```

**You should see** a version for each. Node should be 22 or newer. On Linux and macOS `python3 --version` is the usual name.

> The scripts use OpenTofu if it is installed, otherwise Terraform. Either works.

---

## Step 2. Make the scripts runnable (once)

On **Windows** (Git Bash or MSYS2 have no `unzip`; Python does the same job). These paths match the ITSM folder layout; change them if yours differs:

```bash
cd "/c/Users/$USERNAME/Documents/ITSM/11 GitHub Repos"
python -m zipfile -e "/c/Users/$USERNAME/Documents/ITSM/05 Genesys Cloud CX Labs/2 Citizen Services Lab/genesys-citizen-services-style-lab.zip" .
cd genesys-citizen-services-style-lab
chmod +x scripts/bash/*.sh
ls
```

On **Linux, macOS or WSL**:

```bash
unzip genesys-citizen-services-style-lab.zip -d ~/repos      # change to where you keep your repos
cd ~/repos/genesys-citizen-services-style-lab
chmod +x scripts/bash/*.sh
ls
```

**You should see** the folders `docs`, `scripts`, `terraform` and `tools` from `ls`, and no output from `chmod`. Run every later command from this folder.

---

## Step 3. Set your credentials

**Check that nothing is already set in this shell.** An earlier session can leave values behind, and the scripts would then sign in to whatever org they belong to. This prints names and the region only, never the secret:

```bash
env | grep '^GENESYSCLOUD' | sed 's/SECRET=.*/SECRET=(set, hidden)/'
```

If it prints nothing, good. If it prints values you did not set for this lab, `unset` them (`unset GENESYSCLOUD_OAUTHCLIENT_ID GENESYSCLOUD_OAUTHCLIENT_SECRET GENESYSCLOUD_REGION`) and check whose org they belong to before you go on.

**Use the region name, not the web address.** The scripts and the provider want the name in the first column. Your browser shows the address in the second column after you sign in (for example `apps.usw2.pure.cloud`).

| Where your org lives | `GENESYSCLOUD_REGION` (the name) | Web address ends in |
|---|---|---|
| Sydney | `ap-southeast-2` | `mypurecloud.com.au` |
| US West (Oregon) | `us-west-2` | `usw2.pure.cloud` |
| US East | `us-east-1` | `mypurecloud.com` |
| Canada | `ca-central-1` | `cac1.pure.cloud` |
| Frankfurt | `eu-central-1` | `mypurecloud.de` |
| Dublin | `eu-west-1` | `mypurecloud.ie` |
| London | `eu-west-2` | `euw2.pure.cloud` |
| Tokyo | `ap-northeast-1` | `mypurecloud.jp` |
| Mumbai | `ap-south-1` | `aps1.pure.cloud` |
| Seoul | `ap-northeast-2` | `apne2.pure.cloud` |
| Sao Paulo | `sa-east-1` | `sae1.pure.cloud` |

Check your own address against the Genesys Cloud region list before you rely on this table. A web address such as `usw2.pure.cloud` in `GENESYSCLOUD_REGION` fails with `expected aws_region to be one of [...]`.

Set the three variables. **They exist only in this shell session.** Read the secret silently so it never appears on screen or in your history:

```bash
export GENESYSCLOUD_OAUTHCLIENT_ID="paste-client-id-here"
read -rs -p "Client secret (hidden): " GENESYSCLOUD_OAUTHCLIENT_SECRET; echo; export GENESYSCLOUD_OAUTHCLIENT_SECRET
export GENESYSCLOUD_REGION="ap-southeast-2"
```

Paste your own values. Leave the words inside the quotes on the `read` line exactly as they are: that is only the label of the prompt. Never use an example key from a web page. A real client secret is shown **once**, when you create the OAuth client.

Do not save these in a file in the repo. Do not paste them into chat.

Check they are set without showing the secret:

```bash
[ -n "$GENESYSCLOUD_OAUTHCLIENT_SECRET" ] && echo True
```

---

## Step 4. Preflight (changes nothing)

```bash
./scripts/bash/00-preflight.sh
```

**You should see:** `OK curl found`, `OK jq found`, `OK node found`, `OK tofu found`, `OK Token received for region ap-southeast-2`, and `OK Connected to Genesys org: <your org name>`.

**Check the org name is your lab org.** If it is not, close the shell.

| If you see | Do this |
|---|---|
| `Set GENESYSCLOUD_OAUTHCLIENT_ID` | Step 3 was not done in this shell |
| `Could not get a token` | Wrong client ID, secret or region |
| `'jq' is not installed` | Step 1 |

---

## Step 5. Package the function

```bash
./scripts/bash/01-package-function.sh
```

**You should see:** `# tests 8`, `# pass 8`, `# fail 0`, `OK Built .../normalise-reference.zip`.

---

## Step 6. Initialise and validate

```bash
./scripts/bash/02-init.sh
```

**You should see:** `OK Formatting is clean`, `Success! The configuration is valid.`, `OK Configuration is valid`.

If formatting fails: `cd terraform && tofu fmt -recursive && cd ..`, then run Step 6 again.

After this a file `terraform/.terraform.lock.hcl` exists. **Keep it and commit it.**

**If init says the package "doesn't match any of the checksums previously recorded in the dependency lock file":** the lock file was made on another type of computer. `02-init.sh` now repairs this by itself: it adds checksums for Linux, macOS and Windows and tries again. Only that file changes. By hand, after one `02-init.sh` run:

```bash
tofu -chdir=terraform providers lock -platform=windows_amd64 -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64
```

**If validate says `expected aws_region to be one of [...]`:** `GENESYSCLOUD_REGION` holds a web address. Set it to the region name (see the table in Step 3).

---

## Step 6b. The offline plan test (needs no org)

This plans the whole design four ways (minimal, full, surge switch on, sign-in hardening on) with the Genesys provider **mocked**. It needs no credentials and changes nothing. It catches mistakes that `validate` cannot see, such as a queue with too few rings or a percentage given as 70 instead of 0.70.

```bash
( cd terraform && tofu init -backend=false && tofu test )
```

**You should see** `Success! 4 passed, 0 failed.` OpenTofu 1.8 or Terraform 1.7 or newer is needed.

> It proves the design expands into objects the provider will accept. It does **not** prove Genesys will accept them. Only a real `apply` proves that.

---

## Step 7. Plan (changes nothing)

Smaller build (no AI, quality or web chat), a good first try:

```bash
./scripts/bash/03-plan.sh minimal
```

Full build:

```bash
./scripts/bash/03-plan.sh full
```

Full build plus sign-in hardening (**lab org only**; read `terraform/modules/security/main.tf` first, because a wrong setting can lock everyone out, including you, so keep a second admin session open):

```bash
./scripts/bash/03-plan.sh hardened
```

**You should see** a long list and a line like `Plan: N to add, 0 to change, 0 to destroy.`

**Read the plan.** Names should start with `CS`. On a first run nothing should be changed or destroyed.

---

## Step 8. Apply (this changes Genesys)

```bash
./scripts/bash/04-apply.sh minimal      # or: full
```

It asks you to type `YES`.

**You should see** `Apply complete! Resources: N added`.

If it fails partway: read the **last** error, fix the code, run Steps 7 and 8 again. Terraform adds only what is missing.

---

## Step 9. Inventory

```bash
./scripts/bash/05-inventory.sh
```

**You should see** counts of objects, then a list of queues beginning `CS`.

Now open Genesys Cloud and look at what was built (`BUILD-MANUAL.md`, "Look at what you built"), then run the tests in the Manual, Part 6.

---

## Step 9b. Health check (read-only)

```bash
./scripts/bash/08-health-check.sh
```

**You should see** five numbered checks and `OK  All checks passed`. If a flow is saved but not published, or an expected queue is missing, it prints `FAIL` and exits with 1, so a scheduler or pipeline can alert on it. A `WARN` on the surge switch means someone left it on.

It was tested against a mock server only. If a field name differs in your org, fix the script and note it in your run log.

---

## Step 10. The surge drill

Edit `terraform/envs/full.tfvars`. Remove the `#` from `surge_mode_enabled = true`. Save. Then:

```bash
./scripts/bash/03-plan.sh full
```

**You should see** one change: the emergency group `enabled`. Then:

```bash
./scripts/bash/04-apply.sh full
```

Put the `#` back, plan, apply, to switch it off.

---

## Step 11. Optional: read the org back as Terraform

```bash
./scripts/bash/06-export.sh
```

**You should see** `OK Exported to .../export/generated`. Look, but do not commit: it contains real IDs. `export/` is already in `.gitignore`.

---

## Step 12. Tear down

```bash
./scripts/bash/05-inventory.sh
./scripts/bash/07-destroy.sh
./scripts/bash/05-inventory.sh
```

The destroy script shows what it will delete. Type `DESTROY` to continue. **You should see** `OK Destroyed.` and, in the last inventory, no `CS` queues.

Then check **Admin, Billing** in Genesys and your contract for numbers, add-ons and usage that remain.

---

## Step 13. Put it on GitHub

**13a. Create an empty repository on github.com** (browser). Name it exactly like the folder. Choose **Private** first; you can make it public later. Leave **Add a README**, **.gitignore** and **license** unticked, because the repo already has them.

**13b. Run the safety check** from the repo folder:

```bash
pip install pyyaml python-hcl2      # if pip refuses, use a virtual environment: python3 -m venv .venv && . .venv/bin/activate
python tools/check_repo.py          # Linux and macOS: python3
```

**You should see** `All checks passed.` If it prints `FAIL` lines, stop and fix them. Do not publish.

**13c. Check your git identity** (once per computer). Use GitHub's private address if you do not want your personal email in public history: GitHub, Settings, Emails, the address ending `@users.noreply.github.com`.

```bash
git config --global user.name
git config --global user.email
git config --global user.email "ID+yourname@users.noreply.github.com"   # only if the two lines above are empty or wrong
```

**13d. Create the local repo and read what goes in:**

```bash
git init -b main
git add .
git status
```

Read the list. **You must not see** `.tfstate`, `.tfplan`, `.env`, or `backend.tf`. You should see `terraform/.terraform.lock.hcl`. Do not commit private notes or documents of your own. If you see something that should not go up, stop and fix `.gitignore`.

**13e. Commit and push:**

```bash
git commit -m "Initial commit: Citizen Services-style lab"
git remote add origin https://github.com/asvinluan/genesys-citizen-services-style-lab.git
git push -u origin main
```

The first push asks you to sign in to GitHub (a browser window or a token prompt). Never type a password into the command line.

**13f. Verify:**

```bash
git status -sb
git log --oneline -1
```

**You should see** `## main...origin/main`, your files on GitHub and, within a minute or two, the **Actions** tab running the checks. All four jobs should turn green.

---

## Run the same checks CI runs

```bash
shellcheck -x scripts/bash/*.sh
python tools/check_repo.py          # Linux and macOS: python3
( cd terraform/function-actions/normalise-reference && node --test )
( cd terraform && tofu fmt -check -recursive && tofu init -backend=false && tofu validate && tofu test )
```

---

## Common errors

| What you see | Meaning | Fix |
|---|---|---|
| `No module named hcl2` | The checker's two helpers are missing | `pip install pyyaml python-hcl2` |
| `Permission denied` running a script | Not executable | `chmod +x scripts/bash/*.sh` |
| `Set GENESYSCLOUD_OAUTHCLIENT_ID` | Variables not set in this shell | Step 3 |
| `Could not get a token` | Wrong ID, secret or region | Re-check Part 2 of the Manual |
| `Error: 403` or `missing permission` | The OAuth client's role is too narrow | Add the permission named in the error |
| License or "feature not enabled" | Org lacks AI, WFM, quality or knowledge | Use `minimal`, or set `enable_ai = false` etc. |
| `already exists` | A previous run left an object | Delete it in Genesys, or import it |
| Plan wants to destroy something | Code and org disagree | Do not apply. Find out why first. |
| `Files are not formatted` | Formatting only | `tofu fmt -recursive` in `terraform` |
| `doesn't match any of the checksums previously recorded` | The lock file was made on another type of computer | Rerun `02-init.sh` (it repairs this), or see Step 6 |
| `expected aws_region to be one of [...]` | `GENESYSCLOUD_REGION` holds a web address | Use the region name, for example `us-west-2` (Step 3) |
| `Module not installed` after `providers lock` | The modules were not installed yet | Run `02-init.sh` once first, then the lock command, then `02-init.sh` again |
| `Region 'x' is not in lib.sh` | A region the helper does not know | Use a name from the Step 3 table, or add it to `genesys_domain()` in `lib.sh` |
| `externally-managed-environment` from pip | The system Python is protected | Use a virtual environment (Step 13b) |

---

## What each script does

| Script | Purpose | Changes Genesys |
|---|---|---|
| `00-preflight.sh` | Tools, token, org name | No |
| `01-package-function.sh` | Test and zip the function | No |
| `02-init.sh` | Format check, init, validate | No |
| `03-plan.sh` | Show what would be built | No |
| `04-apply.sh` | Build from the saved plan | **Yes** |
| `05-inventory.sh` | Count lab objects | No |
| `06-export.sh` | Read the org back as Terraform | No |
| `07-destroy.sh` | Delete what this repo built | **Yes** |
| `08-health-check.sh` | Read-only check that what was built is still healthy | No |
| `offline-check.sh` | Everything that needs no org, no ID, no secret | No |
| `lib.sh` | Shared helpers, sourced not run | No |

All scripts stop at the first failure (`set -euo pipefail`). They never print the secret or the token.
