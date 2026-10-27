# Runbook: PowerShell (Windows)

Every command to build the Citizen Services-style lab Genesys Cloud lab from a Windows PC. One action per step. After each step there is **You should see**.

If you prefer Bash, use `RUNBOOK-BASH.md`. The two do the same thing.

**Before you start:** read Part 1 and 2 of `BUILD-MANUAL.md` (a lab org and an OAuth client). **Never run this against a customer's org.**

Works in Windows PowerShell 5.1 and PowerShell 7. Use PowerShell 7 if you can.

> **No Genesys org, client ID or secret yet?** Use `RUNBOOK-OFFLINE-POWERSHELL.md`. It runs everything that needs no org. Come back to this runbook when you have a lab org and an OAuth client.

> **How to paste.** Paste one block at a time and read the result before the next one. Never paste a result back in as a command: lines such as `>>` and `PS C:\...>` belong to the screen, not to you. If a command fails, copy only the command and the error when you ask for help.

---

## Step 1. Install the tools (once)

Open **PowerShell**. Paste these one at a time. `winget` is built into current Windows.

```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e
winget install --id OpenTofu.Tofu -e
winget install --id Python.Python.3.12 -e
```

Type each line exactly. There are two dashes before `id` and **none** before the package name. A line such as `winget install --id --Git.Git -e` fails with `No package found matching input criteria`. If a tool is already installed, winget just upgrades it, which is fine.

**Close PowerShell and open it again** so the new tools are found. A window that was open during the install does not see them, and `node` will say `not recognized`. If you cannot close the window, refresh its path instead:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

Then check:

```powershell
git --version
node --version
tofu version
python --version
```

**You should see** a version number for each. Node should be 22 or newer. If `node` is older, install the current LTS. If `python` is not found, try `py --version`.

> Prefer HashiCorp Terraform? Install it instead of OpenTofu (`winget install --id Hashicorp.Terraform -e`). The scripts use whichever they find, OpenTofu first.

---

## Step 2. Allow scripts to run (once)

Windows blocks scripts by default. This allows scripts **for this window only**:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

**You should see** nothing (that means it worked). You must run it again in every new window.

---

## Step 3. Go to the repo and set your credentials

Unzip the repo zip next to your other clones, then go into the folder. The folder name is the repo name. These paths match the ITSM folder layout; change them only if yours differs.

```powershell
Expand-Archive "$HOME\Documents\ITSM\05 Genesys Cloud CX Labs\2 Citizen Services Lab\genesys-citizen-services-style-lab.zip" "$HOME\Documents\ITSM\11 GitHub Repos\" -Force
cd "$HOME\Documents\ITSM\11 GitHub Repos\genesys-citizen-services-style-lab"
dir
```

**You should see** folders such as `docs`, `scripts`, `terraform` and `tools`. If you see only one folder with a similar name, `cd` into it and run `dir` again. Run every later command from this folder.

**Check that nothing is already set in this window.** An earlier session can leave values behind, and the scripts would then sign in to whatever org they belong to. This prints names and the region only, never the secret:

```powershell
Get-ChildItem Env: | Where-Object Name -like 'GENESYSCLOUD*' | ForEach-Object { if ($_.Name -match 'SECRET') { "$($_.Name) = (set, hidden)" } else { "$($_.Name) = $($_.Value)" } }
```

If it prints nothing, good. If it prints values you did not set for this lab, clear them (`Remove-Item Env:GENESYSCLOUD_OAUTHCLIENT_ID`, and the same for `_SECRET` and `_REGION`) and check whose org they belong to before you go on.

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

Set the three variables. **They exist only in this window.** The secret is read from a hidden prompt, so it never appears on screen or in your history:

```powershell
$env:GENESYSCLOUD_OAUTHCLIENT_ID = "paste-client-id-here"
$s = Read-Host "Client secret (hidden)" -AsSecureString
$env:GENESYSCLOUD_OAUTHCLIENT_SECRET = [System.Net.NetworkCredential]::new("", $s).Password
$env:GENESYSCLOUD_REGION = "ap-southeast-2"
```

Paste your own values. Leave the words inside the quotes on the `Read-Host` line exactly as they are: that is only the label of the prompt, and the real secret goes in when it asks. Never use an example key from a web page. A real client secret is shown **once**, when you create the OAuth client.

> Do not save these in a file. Do not type them into a script. Do not paste them into chat.

Check they are set without showing the secret:

```powershell
[bool]$env:GENESYSCLOUD_OAUTHCLIENT_SECRET
```

It prints `True`.

---

## Step 4. Preflight (changes nothing)

```powershell
.\scripts\powershell\00-preflight.ps1
```

**You should see:** `OK node found`, `OK IaC tool found`, `OK Token received for region ap-southeast-2`, and `OK Connected to Genesys org: <your org name>`.

**Check the org name is your lab org.** If it is not, close the window.

| If you see | Do this |
|---|---|
| `Set GENESYSCLOUD_OAUTHCLIENT_ID` | Step 3 was not done in this window |
| `Could not get a token` | Wrong client ID, secret or region |
| `Neither tofu nor terraform is installed` | Step 1, then reopen PowerShell |

---

## Step 5. Package the function

```powershell
.\scripts\powershell\01-package-function.ps1
```

**You should see:** `# tests 8`, `# pass 8`, `# fail 0`, `OK Built ...normalise-reference.zip`.

---

## Step 6. Initialise and validate

```powershell
.\scripts\powershell\02-init.ps1
```

**You should see:** `OK Formatting is clean`, then `Success! The configuration is valid.`, then `OK Configuration is valid`.

If formatting fails, run `tofu fmt -recursive` inside the `terraform` folder, and run Step 6 again.

After this step a file `terraform\.terraform.lock.hcl` exists. **Keep it and commit it later.**

**If init says the package "doesn't match any of the checksums previously recorded in the dependency lock file":** the lock file was made on another type of computer. `02-init.ps1` now repairs this by itself: it adds checksums for Windows, Linux and macOS to the lock file and tries again. Only that file changes. To do it by hand, run this from the repo folder after one `02-init.ps1` run (it needs the modules installed first), then run Step 6 again:

```powershell
tofu -chdir=terraform providers lock -platform=windows_amd64 -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64
```

**If validate says `expected aws_region to be one of [...]`:** `GENESYSCLOUD_REGION` holds a web address. Set it to the region name (see the table in Step 3).

---

## Step 6b. The offline plan test (needs no org)

This plans the whole design four ways (minimal, full, surge switch on, sign-in hardening on) with the Genesys provider **mocked**. It needs no credentials and changes nothing. It catches mistakes that `validate` cannot see, such as a queue with too few rings or a percentage given as 70 instead of 0.70.

```powershell
cd terraform
tofu init -backend=false
tofu test
cd ..
```

**You should see** `Success! 4 passed, 0 failed.` OpenTofu 1.8 or Terraform 1.7 or newer is needed.

> It proves the design expands into objects the provider will accept. It does **not** prove Genesys will accept them. Only a real `apply` proves that.

---

## Step 7. Plan (changes nothing)

Smaller build (no AI, quality or web chat), a good first try:

```powershell
.\scripts\powershell\03-plan.ps1 -Environment minimal
```

Full build:

```powershell
.\scripts\powershell\03-plan.ps1 -Environment full
```

Full build plus sign-in hardening (**lab org only**; read `terraform\modules\security\main.tf` first, because a wrong setting can lock everyone out, including you, so keep a second admin session open):

```powershell
.\scripts\powershell\03-plan.ps1 -Environment hardened
```

**You should see** a long list and a line like `Plan: N to add, 0 to change, 0 to destroy.`

**Read the plan.** Names should start with `CS`. On a first run, nothing should be changed or destroyed.

If the plan fails, read the **last** error. The most common first-run errors are in the table at the end.

---

## Step 8. Apply (this changes Genesys)

```powershell
.\scripts\powershell\04-apply.ps1 -Environment minimal
```

(or `-Environment full`). It asks you to type `YES`.

**You should see** `Apply complete! Resources: N added`.

If it fails partway: read the error, fix the code, and run Steps 7 and 8 again. Terraform adds only what is missing.

---

## Step 9. Inventory

```powershell
.\scripts\powershell\05-inventory.ps1
```

**You should see** counts of objects, then a list of queues beginning `CS`.

Now open Genesys Cloud and look at what was built (see `BUILD-MANUAL.md`, "Look at what you built"). Then run the tests in the Manual, Part 6.

---

## Step 9b. Health check (read-only)

```powershell
.\scripts\powershell\08-health-check.ps1
```

**You should see** five numbered checks and `OK All checks passed`. If a flow is saved but not published, or an expected queue is missing, it prints `FAIL` and exits with 1, so a scheduler can alert on it. A `WARN` on the surge switch means someone left it on.

It was tested against a mock server only. If a field name differs in your org, fix the script and note it in your run log.

---

## Step 10. The surge drill

Open `terraform\envs\full.tfvars` in Notepad. Remove the `#` from the line `surge_mode_enabled = true`. Save. Then:

```powershell
.\scripts\powershell\03-plan.ps1 -Environment full
```

**You should see** one change: the emergency group `enabled`. Then:

```powershell
.\scripts\powershell\04-apply.ps1 -Environment full
```

Put the `#` back, plan, apply, to switch it off.

---

## Step 11. Optional: read the org back as Terraform

```powershell
.\scripts\powershell\06-export.ps1
```

**You should see** `OK Exported to ...\export\generated`. Open the files, look, and do not commit them: they contain real IDs. The `export` folder is already in `.gitignore`.

---

## Step 12. Tear down

```powershell
.\scripts\powershell\05-inventory.ps1
.\scripts\powershell\07-destroy.ps1
.\scripts\powershell\05-inventory.ps1
```

The destroy script shows what it will delete. Type `DESTROY` to continue. **You should see** `OK Destroyed.` and, in the final inventory, no `CS` queues.

Then check **Admin, Billing** in Genesys and your contract for numbers, add-ons and usage that remain.

---

## Step 13. Put it on GitHub

**13a. Create an empty repository on github.com** (browser). Name it exactly like the folder. Choose **Private** first; you can make it public later. Leave **Add a README**, **.gitignore** and **license** unticked, because the repo already has them.

**13b. Run the safety check** from the repo folder:

```powershell
pip install pyyaml python-hcl2
python tools\check_repo.py
```

**You should see** `All checks passed.` (If `python` is not found, try `py tools\check_repo.py`.) If it prints `FAIL` lines, stop and fix them. Do not publish.

**13c. Check your git identity** (once per computer). Use GitHub's private address if you do not want your personal email in public history: GitHub, Settings, Emails, the address ending `@users.noreply.github.com`.

```powershell
git config --global user.name
git config --global user.email
git config --global user.email "ID+yourname@users.noreply.github.com"
```

(Run the third line only if the first two are empty or wrong.)

**13d. Create the local repo and read what goes in:**

```powershell
git init -b main
git add .
git status
```

Read the `git status` list. **You must not see** `.tfstate`, `.tfplan`, `.env`, or a `backend.tf`. You should see `terraform/.terraform.lock.hcl`. Do not commit private notes or documents of your own. If you see something that should not go up, stop and fix `.gitignore`.

**13e. Commit and push:**

```powershell
git commit -m "Initial commit: Citizen Services-style lab"
git remote add origin https://github.com/asvinluan/genesys-citizen-services-style-lab.git
git push -u origin main
```

The first push opens a browser window to sign in to GitHub. Never type a password or token into the command line.

**13f. Verify:**

```powershell
git status -sb
git log --oneline -1
```

**You should see** `## main...origin/main`, your files on GitHub and, within a minute or two, the **Actions** tab running the checks. All four jobs should turn green.

---

## Common errors

| What you see | Meaning | Fix |
|---|---|---|
| `running scripts is disabled on this system` | Step 2 was not done | Run Step 2 in this window |
| `Set GENESYSCLOUD_OAUTHCLIENT_ID` | Variables not set in this window | Step 3 |
| `Could not get a token` | Wrong ID, secret or region | Re-check Part 2 of the Manual |
| `Error: 403` or `missing permission` | The OAuth client's role is too narrow | Add the permission named in the error |
| License or "feature not enabled" | Org lacks AI, WFM, quality or knowledge | Use `-Environment minimal`, or set `enable_ai = false` etc. in a tfvars |
| `already exists` | A previous run left an object | Delete it in Genesys, or import it |
| Plan wants to destroy something | Code and org disagree | Do not apply. Find out why first. |
| `Files are not formatted` | Formatting only | `tofu fmt -recursive` in `terraform` |
| `No module named hcl2` | The checker's two helpers are missing | `pip install pyyaml python-hcl2` |
| `python is not recognized` | Python not installed | `winget install --id Python.Python.3.12 -e`, reopen PowerShell |
| `No package found matching input criteria` (winget) | A typo in the package name, often an extra `--` | Type `winget install --id Git.Git -e` exactly |
| `node` or `tofu` `is not recognized` right after installing | This window was opened before the install | Close and reopen PowerShell, or run the path refresh in Step 1 |
| `doesn't match any of the checksums previously recorded` | The lock file was made on another type of computer | Rerun `02-init.ps1` (it repairs this), or see Step 6 |
| `expected aws_region to be one of [...]` | `GENESYSCLOUD_REGION` holds a web address | Use the region name, for example `us-west-2` (Step 3) |
| `Module not installed` after `providers lock` | The modules were not installed yet | Run `02-init.ps1` once first, then the lock command, then `02-init.ps1` again |
| `Region 'x' is not in lib.ps1` | A region the helper does not know | Use a name from the Step 3 table, or add it to `Get-GenesysDomain` in `lib.ps1` |

---

## What each script does

| Script | Purpose | Changes Genesys |
|---|---|---|
| `00-preflight.ps1` | Tools, token, org name | No |
| `01-package-function.ps1` | Test and zip the function | No |
| `02-init.ps1` | Format check, init, validate | No |
| `03-plan.ps1` | Show what would be built | No |
| `04-apply.ps1` | Build from the saved plan | **Yes** |
| `05-inventory.ps1` | Count lab objects | No |
| `06-export.ps1` | Read the org back as Terraform | No |
| `07-destroy.ps1` | Delete what this repo built | **Yes** |
| `08-health-check.ps1` | Read-only check that what was built is still healthy | No |
| `offline-check.ps1` | Everything that needs no org, no ID, no secret | No |
| `lib.ps1` | Shared helpers, not run directly | No |

All scripts stop at the first failure. They never print the secret or the token.
