# Offline runbook (Bash): Citizen Services-style lab, no Genesys org needed

This runbook runs **everything that does not need a Genesys org**: no client ID, no secret, no login, nothing created in Genesys, no cost. Use it when you have no org yet, or to prove the repo is healthy on a new computer before you use the credentialed runbook ([RUNBOOK-BASH.md](RUNBOOK-BASH.md)).

**What it proves.** The function tests pass (8 tests). The Terraform formats, initialises and validates against the real Genesys provider schema. The design plans 4 ways (minimal, full, surge_switch_on, hardened) with the provider **mocked**. The repo has no secrets and its flows, queues, lines and groups line up.

**What it does not prove.** That Genesys accepts the objects. Only a real `apply` in a lab org proves that. It also does not test the flows in Architect, the health check, the surge drill or the destroy script: those need an org. Say so honestly if you describe this work.

The PowerShell version is [RUNBOOK-OFFLINE-POWERSHELL.md](RUNBOOK-OFFLINE-POWERSHELL.md).

> **How to paste.** Paste one block at a time and read the result before the next one. Never paste a result back in as a command: lines such as `>>` and `PS C:\...>` belong to the screen, not to you. If a command fails, copy only the command and the error when you ask for help.

---

## Step 1. Install the tools (once)

### Windows

`apt-get` and `sudo` are Linux commands and do not exist on Windows (`Sudo is disabled on this machine` is Windows telling you so). You do not need them. If you already did Step 1 of the PowerShell runbook, skip to the check. Otherwise install the tools **from PowerShell** with winget:

```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e
winget install --id OpenTofu.Tofu -e
winget install --id Python.Python.3.12 -e
```

Type each line exactly: two dashes before `id`, none before the package name. Then **close the bash window and open a new one** so it sees the tools.

**Which bash window?** Any of them works: Git Bash, the MSYS2 window (`UCRT64`) or WSL. What matters is that the check below prints a version for every tool. In Git Bash and MSYS2 the paths look like `/c/Users/YOU/...`.

Check:

```bash
git --version; node --version; tofu version; python --version
```

**You should see** a version for each. Node should be 22 or newer. If one says `command not found`, close the window and open it again; if it still does, run that winget line again from PowerShell.

### Linux, macOS, WSL

```bash
# Debian, Ubuntu, WSL
sudo apt-get update
sudo apt-get install -y git curl unzip zip jq nodejs npm python3 python3-pip python3-venv
# macOS (Homebrew)
brew install git jq node opentofu python
# OpenTofu on Linux: https://opentofu.org/docs/intro/install/  (or HashiCorp Terraform 1.7 or newer)
```

Check:

```bash
git --version; node --version; tofu version; python3 --version
```

**You should see** a version for each. Node should be 22 or newer. If your distribution's `nodejs` is older, install the current LTS from nodejs.org.

---

## Step 2. Nothing to allow

Bash has no execution policy. The scripts need their execute bit, which Step 3 sets.

---

## Step 3. Unzip the repo and go into it

**On Windows** (Git Bash and MSYS2 have no `unzip`, so Python does the job). These paths match the ITSM folder layout; change them only if yours differs:

```bash
cd "/c/Users/$USERNAME/Documents/ITSM/11 GitHub Repos"
python -m zipfile -e "/c/Users/$USERNAME/Documents/ITSM/05 Genesys Cloud CX Labs/2 Citizen Services Lab/genesys-citizen-services-style-lab.zip" .
cd genesys-citizen-services-style-lab
chmod +x scripts/bash/*.sh
ls
```

**On Linux, macOS or WSL:**

```bash
mkdir -p ~/repos
unzip genesys-citizen-services-style-lab.zip -d ~/repos
cd ~/repos/genesys-citizen-services-style-lab
chmod +x scripts/bash/*.sh
ls
```

**You should see** the folders `docs`, `scripts`, `terraform` and `tools`. Run every later command from this folder.

If the folder already exists from an earlier copy, move it aside first (for example rename it to `genesys-citizen-services-style-lab-OLD`) so old files do not mix with the new ones.

---

## Step 4. Make sure no old credentials are in this shell

This prints names and the region only, never the secret:

```bash
env | grep '^GENESYSCLOUD' | sed 's/SECRET=.*/SECRET=(set, hidden)/'
```

**You should see** nothing. If something is listed, you do not need it here. The offline script clears the ID and secret for its own shell, but clear them yourself so you know:

```bash
unset GENESYSCLOUD_OAUTHCLIENT_ID GENESYSCLOUD_OAUTHCLIENT_SECRET GENESYSCLOUD_REGION
```

You never need to type a client ID or secret anywhere in this runbook. **Do not paste an example key from a web page.**

---

## Step 5. Run the offline check

```bash
./scripts/bash/offline-check.sh
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

**What changed on your computer.** Only inside this folder: a `.terraform` folder (downloaded provider and modules), a `dist` folder with the function zip, and possibly `terraform/.terraform.lock.hcl` if it had to add checksums for your type of computer. Nothing was created in Genesys or anywhere on the internet.

---

## Step 6. The same thing one step at a time (optional)

Use this if the single script fails and you want to see which part.

```bash
./scripts/bash/01-package-function.sh      # function tests and zip
./scripts/bash/02-init.sh                  # init and validate
( cd terraform && tofu init -backend=false && tofu test )
pip install pyyaml python-hcl2             # in a virtual environment if pip refuses
python tools/check_repo.py          # Linux and macOS: python3
```

---

## Step 7. Put it on GitHub (optional)

Do this only after Step 5 ends with `Failed: 0`.

**7a. Create an empty repository on github.com** in your browser. Name it exactly `genesys-citizen-services-style-lab`. Choose **Private** first; you can make it public later. Leave **Add a README**, **.gitignore** and **license** unticked, because the repo already has them.

**7b. Check your git identity** (once per computer). To keep your personal email out of public history use GitHub's private address (GitHub, Settings, Emails, the one ending `@users.noreply.github.com`).

```bash
git config --global user.name
git config --global user.email
```

If either is empty or wrong:

```bash
git config --global user.name "Your Name"
git config --global user.email "ID+yourname@users.noreply.github.com"
```

**7c. Create the local repo and read what goes in:**

```bash
git init -b main
git add .
git status
```

Read the list. **You must not see** `.tfstate`, `.tfplan`, `.env` or `backend.tf`. You should see `terraform/.terraform.lock.hcl`. Do not add private notes or documents of your own. If something should not go up, stop and fix `.gitignore`.

**7d. Commit and push:**

```bash
git commit -m "Initial commit: Citizen Services-style lab"
git remote add origin https://github.com/YOUR-USER/genesys-citizen-services-style-lab.git
git push -u origin main
```

Change `YOUR-USER` to your GitHub name. The first push opens a browser window to sign in. Never type a password or token into the command line.

**7e. Verify:**

```bash
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
| `Permission denied` running a script | The execute bit is missing | `chmod +x scripts/bash/*.sh` |
| `node: command not found` or `tofu: command not found` | Not installed, or an old shell | Step 1, then open a new shell |
| `doesn't match any of the checksums previously recorded` | The lock file was made on another type of computer | Nothing to do: `02-init.sh` repairs it and retries. By hand: `tofu -chdir=terraform providers lock -platform=windows_amd64 -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64`, then rerun |
| `Module not installed` after `providers lock` | The modules were not installed yet | Run `02-init.sh` once first, then the lock command |
| `expected aws_region to be one of [...]` | `GENESYSCLOUD_REGION` holds a web address | `unset GENESYSCLOUD_REGION` or set the region name, for example `us-west-2` |
| `externally-managed-environment` from pip | The system Python is protected | `python3 -m venv .venv && . .venv/bin/activate`, then `pip install pyyaml python-hcl2` |
| `No module named hcl2` | The checker's helpers are missing | `pip install pyyaml python-hcl2` |
| A `FAIL` line from the safety check | The repo has a real problem | Read the line, fix it, rerun. Do not publish until it passes |

---

## When you get a lab org

Switch to [RUNBOOK-BASH.md](RUNBOOK-BASH.md). It uses an OAuth client ID and secret, which you create in the lab org, and it adds the steps that need an org: preflight, plan against the org, apply, inventory, health check, the surge drill and destroy. **Never run it against a customer or employer org.**
