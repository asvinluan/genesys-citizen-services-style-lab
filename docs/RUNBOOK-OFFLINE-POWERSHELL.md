# Offline runbook (PowerShell): Citizen Services-style lab, no Genesys org needed

This runbook runs **everything that does not need a Genesys org**: no client ID, no secret, no login, nothing created in Genesys, no cost. Use it when you have no org yet, or to prove the repo is healthy on a new computer before you use the credentialed runbook ([RUNBOOK-POWERSHELL.md](RUNBOOK-POWERSHELL.md)).

**What it proves.** The function tests pass (8 tests). The Terraform formats, initialises and validates against the real Genesys provider schema. The design plans 4 ways (minimal, full, surge_switch_on, hardened) with the provider **mocked**. The repo has no secrets and its flows, queues, lines and groups line up.

**What it does not prove.** That Genesys accepts the objects. Only a real `apply` in a lab org proves that. It also does not test the flows in Architect, the health check, the surge drill or the destroy script: those need an org. Say so honestly if you describe this work.

The Bash version is [RUNBOOK-OFFLINE-BASH.md](RUNBOOK-OFFLINE-BASH.md).

> **How to paste.** Paste one block at a time and read the result before the next one. Never paste a result back in as a command: lines such as `>>` and `PS C:\...>` belong to the screen, not to you. If a command fails, copy only the command and the error when you ask for help.

---

## Step 1. Install the tools (once)

```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e
winget install --id OpenTofu.Tofu -e
winget install --id Python.Python.3.12 -e
```

Type each line exactly. There are two dashes before `id` and **none** before the package name. `winget install --id --Git.Git -e` fails with `No package found matching input criteria`. If a tool is already installed, winget upgrades it, which is fine. If winget asks you to accept terms, say yes.

**Close PowerShell and open it again.** A window that was open during the install does not see the new tools, and `node` will say `not recognized`. If you cannot close the window, refresh its path instead:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

Check:

```powershell
git --version
node --version
tofu version
python --version
```

**You should see** a version for each. Node should be 22 or newer. If `python` is not found, try `py --version`.

---

## Step 2. Allow scripts in this window only

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

If PowerShell asks to confirm, answer `A` (yes to all). This lasts until you close the window and changes nothing on the computer. Do it again in every new window.

---

## Step 3. Unzip the repo and go into it

These paths match the ITSM folder layout; change them only if yours differs. If the repo folder already exists from an earlier copy, rename it first (for example to `genesys-citizen-services-style-lab-OLD`) so old files do not mix with the new ones.

```powershell
Expand-Archive "$HOME\Documents\ITSM\05 Genesys Cloud CX Labs\2 Citizen Services Lab\genesys-citizen-services-style-lab.zip" "$HOME\Documents\ITSM\11 GitHub Repos\" -Force
cd "$HOME\Documents\ITSM\11 GitHub Repos\genesys-citizen-services-style-lab"
dir
```

**You should see** folders `docs`, `scripts`, `terraform` and `tools`. If you see only one folder with a similar name, `cd` into it and run `dir` again. Run every later command from this folder.

---

## Step 4. Make sure no old credentials are in this window

This prints names and the region only, never the secret:

```powershell
Get-ChildItem Env: | Where-Object Name -like 'GENESYSCLOUD*' | ForEach-Object { if ($_.Name -match 'SECRET') { "$($_.Name) = (set, hidden)" } else { "$($_.Name) = $($_.Value)" } }
```

**You should see** nothing. If something is listed, you do not need it for this runbook. The offline script clears the ID and secret for its own window, but clear them yourself so you know:

```powershell
Remove-Item Env:GENESYSCLOUD_OAUTHCLIENT_ID, Env:GENESYSCLOUD_OAUTHCLIENT_SECRET, Env:GENESYSCLOUD_REGION -ErrorAction SilentlyContinue
```

You never need to type a client ID or secret anywhere in this runbook. **Do not paste an example key from a web page.**

---

## Step 5. Run the offline check

```powershell
.\scripts\powershell\offline-check.ps1
```

It takes about a minute the first time, because it downloads the Genesys provider. It runs four stages and stops at the first failure:

| Stage | What it does | You should see |
|---|---|---|
| 1 of 4 | Function tests, then builds the function zip | `# tests 8`, `# pass 8`, then `OK Built ... normalise-reference.zip` |
| 2 of 4 | Format check, `init`, `validate` | `OK Configuration is valid` |
| 3 of 4 | Offline plan test, provider mocked | `Success! 4 passed, 0 failed.` |
| 4 of 4 | Repo safety check | `All checks passed.` |

The last lines are:

```text
OK  Offline check finished. Passed: 4. Skipped: 0. Failed: 0.
Not run (these need a real Genesys org): preflight, plan against the org, apply, inventory, health check, drills, destroy.
```

`Skipped: 1` means Python was missing, so the safety check was skipped. Install Python (Step 1), open a new window and run it again.

**What changed on your computer.** Only inside this folder: a `.terraform` folder (downloaded provider and modules), a `dist` folder with the function zip, and possibly `terraform\.terraform.lock.hcl` if it had to add checksums for your type of computer. Nothing was created in Genesys or anywhere on the internet.

---

## Step 6. The same thing one step at a time (optional)

Use this if the single script fails and you want to see which part.

```powershell
.\scripts\powershell\01-package-function.ps1    # function tests and zip
.\scripts\powershell\02-init.ps1                # init and validate
cd terraform
tofu init -backend=false
tofu test
cd ..
pip install pyyaml python-hcl2
python tools\check_repo.py
```

---

## Step 7. Put it on GitHub (optional)

Do this only after Step 5 ends with `Failed: 0`.

**7a. Create an empty repository on github.com** in your browser. Name it exactly `genesys-citizen-services-style-lab`. Choose **Private** first; you can make it public later. Leave **Add a README**, **.gitignore** and **license** unticked, because the repo already has them.

**7b. Check your git identity** (once per computer). To keep your personal email out of public history use GitHub's private address (GitHub, Settings, Emails, the one ending `@users.noreply.github.com`).

```powershell
git config --global user.name
git config --global user.email
```

If either is empty or wrong:

```powershell
git config --global user.name "Your Name"
git config --global user.email "ID+yourname@users.noreply.github.com"
```

**7c. Create the local repo and read what goes in:**

```powershell
git init -b main
git add .
git status
```

Read the list. **You must not see** `.tfstate`, `.tfplan`, `.env` or `backend.tf`. You should see `terraform\.terraform.lock.hcl`. Do not add private notes or documents of your own. If something should not go up, stop and fix `.gitignore`.

**7d. Commit and push:**

```powershell
git commit -m "Initial commit: Citizen Services-style lab"
git remote add origin https://github.com/YOUR-USER/genesys-citizen-services-style-lab.git
git push -u origin main
```

Change `YOUR-USER` to your GitHub name. The first push opens a browser window to sign in. Never type a password or token into the command line.

**7e. Verify:**

```powershell
git status -sb
git log --oneline -1
```

**You should see** `## main...origin/main`, your files on GitHub and, within a minute or two, the **Actions** tab running the checks. The four jobs should turn green. The CI workflow file is in `.github/workflows/ci.yml`.

---

## What you can say, honestly

- "Designed and coded as Terraform, validated against the real provider schema, with an offline plan test and a repo safety check in CI."
- "Not applied to a live org. The flows are not checked in Architect."

Do **not** say it ran in production, or that Genesys accepted it.

---

## Common errors

| What you see | Why | What to do |
|---|---|---|
| `No package found matching input criteria` | A typo in the package name, often an extra `--` | Type `winget install --id Git.Git -e` exactly |
| `node` or `tofu` `is not recognized` after installing | This window was opened before the install | Close and reopen PowerShell, or run the path refresh in Step 1 |
| `running scripts is disabled on this system` | Execution policy | Step 2, in the same window |
| `cd` says the path does not exist | The unzip put the repo in another folder | Run `dir` in the folder you unzipped to and `cd` into the repo folder |
| `doesn't match any of the checksums previously recorded` | The lock file was made on another type of computer | Nothing to do: `02-init.ps1` repairs it and retries. By hand: run `tofu -chdir=terraform providers lock -platform=windows_amd64 -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64` and rerun |
| `Module not installed` after `providers lock` | The modules were not installed yet | Run `02-init.ps1` once first, then the lock command |
| `expected aws_region to be one of [...]` | `GENESYSCLOUD_REGION` holds a web address | Clear it (Step 4) or set the region name, for example `us-west-2` |
| `python is not recognized` | Python not installed, or old window | Step 1, then reopen PowerShell. The script skips the safety check and says so |
| `No module named hcl2` | The checker's helpers are missing | `pip install pyyaml python-hcl2` |
| A `FAIL` line from the safety check | The repo has a real problem | Read the line, fix it, rerun. Do not publish until it passes |

---

## When you get a lab org

Switch to [RUNBOOK-POWERSHELL.md](RUNBOOK-POWERSHELL.md). It uses an OAuth client ID and secret, which you create in the lab org, and it adds the steps that need an org: preflight, plan against the org, apply, inventory, health check, the surge drill and destroy. **Never run it against a customer or employer org.**
