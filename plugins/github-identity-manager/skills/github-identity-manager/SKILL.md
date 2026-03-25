---
name: github-identity-manager
description: "Manual invocation only. Set up, repair, or modify multi-account GitHub identity management. Two key backends: 1Password (keys in vault, Touch ID signing) or disk keys (keys in ~/.ssh/, passphrase in macOS Keychain, zero prompts). Configures git CLI (SSH auth + commit signing), gh CLI (per-directory account switching) — all with directory-based automatic account selection. Includes migration between backends. Use when user explicitly invokes this skill."
---

# GitHub Identity Manager

Manages GitHub identity: SSH auth, commit signing, and `gh` CLI — with automatic directory-based account switching.

**Two key backends:**

| | 1Password | Disk Keys |
|---|---|---|
| Private keys | 1Password vault | `~/.ssh/` on disk |
| SSH agent | 1Password SSH agent | macOS ssh-agent |
| Commit signing | `op-ssh-sign` (Touch ID prompt) | `ssh-keygen` (silent, no prompt) |
| Auth experience | Touch ID (configurable frequency) | Passphrase in macOS Keychain (zero prompts) |
| Extra requirements | 1Password 8+ with subscription | None |

**Shared across both backends:**
- `includeIf` directory-based git config switching
- Per-account gitconfigs (user, email, signingkey)
- `gpg.format = ssh` for commit signing
- direnv for `gh` CLI auto-switching
- All remotes use `git@github.com:`

**macOS only.** Requires Git 2.36+.

**Technical references (read on demand):**
- `references/setup-guide.md` — 1Password setup (full step-by-step)
- `references/disk-keys-guide.md` — Disk keys setup (full step-by-step)
- `references/migration-guide.md` — Migration between backends

---

## On Start

### Prerequisites check (common)

```bash
git --version       # Must be 2.36+
which gh            # Must be installed
which direnv        # Must be installed
```

- **git missing/old** → `brew install git`
- **gh missing** → `brew install gh`
- **direnv missing** → `brew install direnv` + shell hook ([direnv setup](https://direnv.net/docs/hook.html))

### Detect current backend

```bash
# 1Password signals
ls /Applications/1Password.app 2>/dev/null
ls ~/.1password/agent.sock 2>/dev/null
cat ~/.ssh/config 2>/dev/null | grep -i IdentityAgent

# Disk key signals
cat ~/.ssh/config 2>/dev/null | grep -i UseKeychain
ls ~/.ssh/id_ed25519_* 2>/dev/null

# Common signals
cat ~/.gitconfig 2>/dev/null | grep -c includeIf
gh auth status 2>&1 | grep -c "Logged in"
cat ~/.gitconfig 2>/dev/null | grep -i "gpg.ssh.program\|op-ssh-sign"
```

Backend determination:
- **IdentityAgent + op-ssh-sign** → 1Password backend
- **UseKeychain + IdentityFile (no IdentityAgent)** → Disk keys backend
- **Mixed/unclear** → ask user
- **Neither** → new setup (will ask in Phase 1)

### Mode detection

- **All signals present** for detected backend → **Repair mode**
- **Some or none** → **Setup mode** (partial = resume from where it broke)
- **User mentions migration** → **Migration mode**
- **User mentions specific task** (add account, change folder, etc.) → **Incremental change** (handle directly)

---

## Incremental Changes

If user invokes with a specific request, handle it directly.

### "Add a new GitHub account"

1. Ask: account username, directory for repos
2. Ask: key name suffix (e.g. `github_work`) — explain it becomes part of the filename
3. **1Password backend:**
   - Guide user to create Ed25519 key in 1Password
   - Save pub key to `~/.ssh/<suffix>_1p.pub`
   - Add vault to `agent.toml` if needed
4. **Disk keys backend:**
   - `ssh-keygen -t ed25519 -C "<email>" -f ~/.ssh/id_ed25519_<suffix>`
   - `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_<suffix>`
5. Add `includeIf` block to `~/.gitconfig`
6. Create `~/.gitconfig-<suffix>` with user/signing/sshCommand for the detected backend
7. `gh auth login` for the new account
8. Create `.envrc` in account directory
9. Add key to GitHub (Authentication + Signing)
10. Verify with test commit

### "Change my repo directory"

1. Ask: which account, old dir, new dir
2. Update `includeIf "gitdir:..."` in `~/.gitconfig`
3. Move `.envrc` to new directory (or update path)
4. Verify

### "My key changed" / "Regenerate key"

1. Ask: which account
2. **1Password:** get new public key from user, update `~/.ssh/<suffix>_1p.pub`
3. **Disk keys:** `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_<suffix>`, then `ssh-add --apple-use-keychain`
4. Update `signingkey` in `~/.gitconfig-<suffix>`
5. Update key on GitHub (remove old, add new — both Auth + Signing)
6. Verify

### "Remove an account"

1. Ask: which account
2. Remove `includeIf` block from `~/.gitconfig`
3. Backup `~/.gitconfig-<suffix>` to `~/.ssh/backup/`
4. **Disk keys:** backup private key to `~/.ssh/backup/`
5. Remove `.envrc` from the account's directory
6. `gh auth logout <account>`
7. Tell user to remove key from GitHub manually

---

## Repair Mode

Run checks **in order**. Stop at first failure, report, ask to fix.

### Check 1: Prerequisites
```bash
git --version    # 2.36+
which gh
which direnv
```
**1Password only:** `ls /Applications/1Password.app/Contents/MacOS/op-ssh-sign`

### Check 2: SSH agent

**1Password:**
```bash
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
# Must list keys. Empty/error → agent not running or symlink broken
```

**Disk keys:**
```bash
ssh-add -l
# Must list keys. Empty → run ssh-add --apple-use-keychain for each key
```

### Check 3: SSH config

**1Password:** must have `IdentityAgent ~/.1password/agent.sock`, no stale Host aliases.

**Disk keys:** must have `AddKeysToAgent yes` and `UseKeychain yes`. No `IdentityAgent`.

```bash
cat ~/.ssh/config
```

### Check 4: Git directory switching
```bash
cat ~/.gitconfig | grep -A1 includeIf
# Must have includeIf blocks for each account directory
```

### Check 5: Per-account gitconfigs

For each `~/.gitconfig-<suffix>`, verify:

**Both backends:**
- `[user]` name, email, signingkey
- `[gpg] format = ssh`
- `[core] sshCommand` set with correct key path + `-o IdentitiesOnly=yes`

**1Password only:**
- `[gpg "ssh"] program = .../op-ssh-sign`
- `signingkey` is literal public key string
- `sshCommand` uses `~/.ssh/<suffix>_1p.pub`

**Disk keys only:**
- No `gpg.ssh.program` (defaults to `ssh-keygen`)
- `signingkey` is path to `.pub` file
- `sshCommand` uses `~/.ssh/id_ed25519_<suffix>`

### Check 6: Public keys match agent

**1Password:**
```bash
ssh-keygen -lf ~/.ssh/<suffix>_1p.pub
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
# Fingerprints must match
```

**Disk keys:**
```bash
ssh-keygen -lf ~/.ssh/id_ed25519_<suffix>.pub
ssh-add -l
# Fingerprints must match
```

### Check 7: SSH auth per account

For each account, from a repo in the matching directory:
```bash
ssh -T git@github.com 2>&1
# Must show correct username
```

### Check 8: Commit signing

For each account:
```bash
git commit --allow-empty -m "verify signing"
git log --show-signature -1
# Must show valid signature
# 1Password: Touch ID should prompt (unless authorize=unlock)
# Disk keys: silent, no prompt
```

### Check 9: gh CLI per account

For each account directory:
```bash
cd ~/<directory>/some-repo && gh auth status
# Must show correct account
cat ~/<directory>/.envrc | grep GH_TOKEN
```

### Check 10: Remotes use SSH
```bash
for dir in ~/<directory>/*/; do
  [ -d "$dir/.git" ] || continue
  url=$(git -C "$dir" remote get-url origin 2>/dev/null)
  echo "$(basename $dir): $url"
done
# All should be git@github.com:... (not https://, not Host aliases)
```

### Report

Summarize: what passed, what failed (with specific fix for each). Ask permission before fixing.

---

## Setup Mode

### Phase 1: Discovery

**Never assume — discover and ask. One question at a time.**

1. **How many GitHub accounts?** Username and purpose of each.

2. **Key backend choice:**

   > "How do you want to manage your SSH keys?
   >
   > 1. **1Password** — keys stored in 1Password vault, signing via Touch ID. Requires 1Password 8+.
   > 2. **Disk keys** — keys in `~/.ssh/`, passphrase stored in macOS Keychain. Zero prompts after initial setup.
   >
   > Which one?"

   **If 1Password chosen:** verify 1Password is installed + `op-ssh-sign` exists. If not, tell user to install.

3. **Key name suffix:**

   > "What suffix do you want for each account's SSH key files? This becomes part of the filename.
   >
   > Examples:
   > - `github_interstella` → `~/.ssh/id_ed25519_github_interstella` (disk) or `~/.ssh/github_interstella_1p.pub` (1Password)
   > - `personal` → `~/.ssh/id_ed25519_personal`
   >
   > The suffix is also used for the per-account git config file (`~/.gitconfig-<suffix>`).
   >
   > What suffix for each account?"

4. **Where are repos?** Scan:
   ```bash
   find ~ -maxdepth 3 -name ".git" -type d 2>/dev/null | head -30
   ```
   Group by parent directory. If not separated by account, **propose** a layout (e.g. `~/work/`, `~/personal/`). **Never move repos without explicit per-repo confirmation.**

5. **Existing SSH keys?**
   ```bash
   ls -la ~/.ssh/*.pub ~/.ssh/**/*.pub 2>/dev/null
   cat ~/.ssh/config 2>/dev/null
   ssh-add -l 2>/dev/null
   ```

6. **Existing signing/GPG?**
   ```bash
   git config --global gpg.format
   git config --global user.signingkey
   git config --global gpg.ssh.program
   ```

7. **1Password SSH keys?** (only if 1Password backend)
   > "Do you have SSH keys in 1Password for GitHub already? If yes, tell me their names. If not, I'll guide you through creating them."

8. **1Password vaults?** (only if 1Password backend)
   > "Are your SSH keys all in the same 1Password vault, or different vaults?"

9. **gh CLI status?**
   ```bash
   gh auth status 2>&1
   ```

10. **Non-GitHub SSH usage?**
    > "Do you use SSH keys for anything other than GitHub? (VPS, servers, other git hosting) — I need to know so I don't break those connections."

### Phase 2: Present Plan

Before touching anything, show what will be created/modified. Adapt to chosen backend:

**Both backends:**
- `~/.ssh/config` — SSH agent/keychain configuration
- `~/.gitconfig` — directory-based account switching (`includeIf`)
- `~/.gitconfig-<suffix>` per account — SSH key, signing, identity
- `<directory>/.envrc` per account — direnv `gh` CLI auto-switching

**1Password only:**
- `~/.ssh/<suffix>_1p.pub` — public keys for key selection
- `~/.config/1Password/ssh/agent.toml` — vault configuration

**Disk keys only:**
- `~/.ssh/id_ed25519_<suffix>` + `.pub` per account — key pairs on disk

**User must do manually:**
- **1Password:** Create SSH keys in 1Password (guided)
- **Both:** Add keys to GitHub as Authentication + Signing keys
- **Both:** `gh auth login` for each account (prompted when)

Ask for confirmation before proceeding.

### Phase 3: Execute

Follow the appropriate reference guide. For each step: explain → do → verify → next.

**1Password backend** → follow `references/setup-guide.md`

**Disk keys backend** → follow `references/disk-keys-guide.md`

**Both backends share these steps:**
- Git config (`includeIf` + per-account configs)
- gh CLI setup (direnv + `.envrc`)
- Add keys to GitHub (Auth + Signing)
- Fix HTTPS/Host-alias remotes

**For single-account setup:** skip `includeIf`, put everything in `~/.gitconfig` directly. Skip direnv.

### Phase 4: Verify

Run all Repair Mode checks (1-10) for the chosen backend. Everything should pass.

### Phase 5: Cleanup

If old infrastructure found (from previous setup or other backend):

> "I found remnants of a previous setup:
> - [list: GPG, old keys, GPG_TTY, Host aliases, 1Password config, etc.]
>
> Want me to clean these up?"

**SSH keys:** backup to `~/.ssh/backup/` (never delete):
> "Old keys backed up to `~/.ssh/backup/`. To remove permanently: `trash ~/.ssh/backup/` (moves to macOS Trash — still recoverable). Keys used for non-GitHub purposes were NOT touched."

**GitHub keys:** tell user to manually review at https://github.com/settings/keys — for each account.

---

## Migration Mode

When user wants to switch backends. Read `references/migration-guide.md` for technical details.

### 1Password → Disk Keys

1. **Cannot export private keys from 1Password** — must generate new keys
2. Generate new disk keys with user's chosen suffix
3. Add new keys to macOS Keychain (`ssh-add --apple-use-keychain`)
4. Add new keys to GitHub (keep old 1Password keys active during transition)
5. Update `~/.ssh/config` — replace `IdentityAgent` with `AddKeysToAgent yes` + `UseKeychain yes`
6. Update per-account gitconfigs — remove `op-ssh-sign`, update paths
7. Verify everything works
8. Remove old 1Password keys from GitHub
9. Clean up 1Password SSH config (agent.toml, symlink)

### Disk Keys → 1Password

1. Guide user to create Ed25519 keys in 1Password
2. Enable 1Password SSH agent + configure `agent.toml`
3. Save public keys to `~/.ssh/<suffix>_1p.pub`
4. Add new keys to GitHub (keep old disk keys active during transition)
5. Update `~/.ssh/config` — replace `UseKeychain`/`AddKeysToAgent` with `IdentityAgent`
6. Update per-account gitconfigs — add `op-ssh-sign`, update paths
7. Verify everything works
8. Remove old disk keys from GitHub
9. Backup old disk keys to `~/.ssh/backup/`

### During migration

- **Both key sets active on GitHub** simultaneously — zero downtime
- Test thoroughly before removing old keys
- If anything breaks, old keys still work as fallback

---

## Critical Rules

- **macOS only**
- **Never delete private keys** — `mv` to backup, suggest `trash` for permanent removal
- **Never move repos** without per-repo confirmation
- **Always verify after each step**
- **Ask about non-GitHub SSH usage** before touching any key or SSH config
- **One question at a time**
- **Show don't tell** — run commands to discover, don't ask user to describe
- **`trash` over `rm`** — always mention it moves to macOS Trash (recoverable)
- **Key suffix is user's choice** — always ask, suggest based on account names, never assume
