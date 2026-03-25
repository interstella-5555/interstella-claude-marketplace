# Multi-Account GitHub SSH + Commit Signing with Disk Keys

Complete guide for setting up multiple GitHub accounts on one machine with:
- **SSH authentication** via on-disk keys + macOS ssh-agent
- **Commit signing** via SSH keys (Git 2.34+ native `ssh-keygen`, no external tools)
- **Automatic account switching** based on directory (`~/work/` vs `~/personal/`)
- **Passphrase in macOS Keychain** — enter once during setup, never again

> **For Claude Code / AI assistants:** This document is a complete setup guide for the **disk keys** backend. Follow each section in order. Adapt directory paths, account names, and key suffixes to the user's setup.

---

## Prerequisites

- macOS
- [Git 2.36+](https://git-scm.com/) (for `includeIf` + `core.sshCommand`)
- [GitHub CLI](https://cli.github.com/) (`gh`) — optional, for `gh` CLI switching
- [direnv](https://direnv.net/) — for automatic `gh` CLI account switching
- Two (or more) GitHub accounts

### Verify git version

```bash
git --version
# Needs 2.36+
```

---

## Step 1: Generate SSH keys

For **each** GitHub account, generate an Ed25519 key pair with a descriptive suffix:

```bash
ssh-keygen -t ed25519 -C "<email>" -f ~/.ssh/id_ed25519_<suffix>
# Enter a passphrase when prompted — this protects the key at rest
```

The `<suffix>` is the user's choice. Examples:

```bash
# Account: interstella-5555, suffix: github_interstella
ssh-keygen -t ed25519 -C "karol@interstella.com" -f ~/.ssh/id_ed25519_github_interstella

# Account: paz-ts, suffix: github_thorswap
ssh-keygen -t ed25519 -C "karol@thorswap.com" -f ~/.ssh/id_ed25519_github_thorswap
```

This creates two files per key:
- `~/.ssh/id_ed25519_<suffix>` — private key (encrypted with passphrase)
- `~/.ssh/id_ed25519_<suffix>.pub` — public key (not secret, safe to share)

Ref: [ssh-keygen(1) man page](https://man.openbsd.org/ssh-keygen)

---

## Step 2: Add keys to macOS Keychain

Store the passphrase in macOS Keychain so you never need to type it again:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github_interstella
# Enter passphrase — Keychain stores it permanently

ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github_thorswap
# Enter passphrase — Keychain stores it permanently
```

Verify keys are loaded:

```bash
ssh-add -l
# Should list both keys with their fingerprints
```

The [`--apple-use-keychain`](https://developer.apple.com/library/archive/technotes/tn2449/_index.html) flag (macOS-specific) tells `ssh-add` to store the passphrase in the system Keychain. The Keychain is unlocked when you log into your Mac, so the passphrase is available automatically without any prompts.

---

## Step 3: Configure SSH

**File: `~/.ssh/config`** ([`ssh_config(5)` man page](https://man.openbsd.org/ssh_config))

```
Host *
  AddKeysToAgent yes
  UseKeychain yes
```

That's it. No per-host blocks, no IdentityFile directives here. Git handles key selection via `core.sshCommand` (next step).

- [`AddKeysToAgent yes`](https://man.openbsd.org/ssh_config#AddKeysToAgent) — automatically adds keys to the running agent after first authentication
- [`UseKeychain yes`](https://developer.apple.com/library/archive/technotes/tn2449/_index.html) — reads/stores passphrases from macOS Keychain (macOS-specific extension)

Together, these mean: the ssh-agent always has your keys loaded, passphrases come from Keychain, and you never see a prompt.

---

## Step 4: Configure Git

### Global config

**File: `~/.gitconfig`** ([git-config docs](https://git-scm.com/docs/git-config))

```ini
[commit]
    gpgsign = true
[init]
    defaultBranch = main
[push]
    autoSetupRemote = true
[pull]
    ff = only

# Directory-based account switching
[includeIf "gitdir:~/code/"]
    path = ~/.gitconfig-github_interstella
[includeIf "gitdir:~/thorswap/"]
    path = ~/.gitconfig-github_thorswap
```

Ref: [Git — Conditional Includes (`includeIf`)](https://git-scm.com/docs/git-config#_conditional_includes)

### Per-account configs

**File: `~/.gitconfig-github_interstella`**

```ini
[user]
    name = Your Name
    email = your-noreply@users.noreply.github.com
    signingkey = ~/.ssh/id_ed25519_github_interstella.pub
[gpg]
    format = ssh
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_github_interstella -o IdentitiesOnly=yes
```

**File: `~/.gitconfig-github_thorswap`**

```ini
[user]
    name = Your Work Name
    email = your-work-noreply@users.noreply.github.com
    signingkey = ~/.ssh/id_ed25519_github_thorswap.pub
[gpg]
    format = ssh
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_github_thorswap -o IdentitiesOnly=yes
```

### How it works

- [`includeIf "gitdir:"`](https://git-scm.com/docs/git-config#_conditional_includes) — git loads the matching config file based on repo directory
- [`core.sshCommand`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-coresshCommand) — tells git to use `ssh -i <private-key>` for this account's repos
- [`-o IdentitiesOnly=yes`](https://man.openbsd.org/ssh_config#IdentitiesOnly) — prevents the agent from offering other keys (avoids GitHub picking the wrong account)
- [`user.signingkey`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-usersigningKey) — points to the public key file; `ssh-keygen` reads it for signing
- **No `gpg.ssh.program` needed** — Git defaults to `ssh-keygen` which handles SSH signing natively since Git 2.34

**Key difference from 1Password setup:** `core.sshCommand` uses `-i <private-key>` (the private key file), not `-i <public-key>.pub`. SSH reads the private key directly from disk (decrypted via agent/Keychain). The `signingkey` points to the `.pub` file because `ssh-keygen -Y sign` reads the public key to identify which key to sign with.

---

## Step 5: Add keys to GitHub

For **each** GitHub account, add the corresponding SSH public key as **both** Authentication and Signing key:

1. Copy the public key:
   ```bash
   cat ~/.ssh/id_ed25519_github_interstella.pub | pbcopy
   ```
2. Log into the GitHub account
3. Go to https://github.com/settings/ssh/new
4. Add as **Authentication Key** (for push/pull/clone)
5. Add the same public key again as **Signing Key** (for verified commits)

Repeat for each account.

Ref: [GitHub — Adding a new SSH key to your account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

---

## Step 6: gh CLI via direnv

Install direnv if not present:
```bash
which direnv || brew install direnv
```

Ensure direnv hook is in shell config (`~/.zshrc`):
```bash
grep -q 'direnv hook' ~/.zshrc || echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
```

For each account, `gh auth login`:
```bash
gh auth login
# Interactive: GitHub.com → SSH → select key → authenticate in browser
```

Create `.envrc` in each account's root directory:

```bash
echo 'export GH_TOKEN=$(gh auth token --user interstella-5555)' > ~/code/.envrc
direnv allow ~/code/.envrc

echo 'export GH_TOKEN=$(gh auth token --user paz-ts)' > ~/thorswap/.envrc
direnv allow ~/thorswap/.envrc
```

`gh auth token --user <name>` reads the stored OAuth token from macOS Keychain ([gh environment docs](https://cli.github.com/manual/gh_help_environment)). direnv loads `.envrc` from parent directories automatically.

---

## Step 7: Fix existing remotes

If any repos use HTTPS or Host aliases, convert them to plain SSH:

```bash
# Fix HTTPS → SSH
git remote set-url origin git@github.com:org/repo.git

# Bulk fix all repos in a directory
for dir in ~/code/*/; do
  [ -d "$dir/.git" ] || continue
  url=$(git -C "$dir" remote get-url origin 2>/dev/null)
  if echo "$url" | grep -q "https://github.com/"; then
    new_url=$(echo "$url" | sed 's|https://github.com/|git@github.com:|')
    git -C "$dir" remote set-url origin "$new_url"
    echo "Fixed: $(basename $dir)"
  fi
done
```

---

## Step 8: Verify

```bash
# Test SSH auth (should show correct account name — no passphrase prompt)
cd ~/code/some-repo && ssh -T git@github.com
# → Hi interstella-5555! You've successfully authenticated...

cd ~/thorswap/some-repo && ssh -T git@github.com
# → Hi paz-ts! You've successfully authenticated...

# Test commit signing (should be completely silent — no prompts)
cd ~/code/some-repo && git commit --allow-empty -m "test signing"
git log --show-signature -1
# → Good "git" signature with ED25519 key...

# Check on GitHub
git push
# Commit should show "Verified" badge
```

---

## Optional: Clean up previous setup

After switching to disk keys, you can remove infrastructure from a previous setup:

- **1Password SSH agent config** — remove `IdentityAgent` from `~/.ssh/config`, remove `~/.1password/agent.sock` symlink
- **1Password agent.toml** — `~/.config/1Password/ssh/agent.toml` (can leave if still using 1Password for other things)
- **1Password public keys** — `~/.ssh/1password/` directory
- **op-ssh-sign references** — remove `gpg.ssh.program` from any gitconfig files
- **GPG installation** — `brew uninstall gnupg` if only used for git signing
- **GPG data** — `rm -rf ~/.gnupg`
- **GPG shell config** — remove `GPG_TTY` from `~/.zshrc`
- **Old keys on GitHub** — manually review at https://github.com/settings/keys and remove keys no longer needed

---

## Troubleshooting

### "Permission denied (publickey)" on push/pull

1. Check agent has key: `ssh-add -l`
2. If empty: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_<suffix>`
3. Check correct key is offered: `GIT_SSH_COMMAND="ssh -v" git fetch 2>&1 | grep Offering`
4. Check `core.sshCommand` is set: `git config core.sshCommand`
5. Check the key is added to GitHub as **Authentication Key**

### Commit shows "Unverified" on GitHub

1. Check the key is added to GitHub as **Signing Key** (not just Authentication)
2. Check `git config user.email` matches the email on your GitHub account
3. Check `git config user.signingkey` points to existing `.pub` file
4. Test locally: `git log --show-signature -1`

### Agent loses keys after restart

1. Check `~/.ssh/config` has both `AddKeysToAgent yes` and `UseKeychain yes`
2. Manually re-add: `ssh-add --apple-use-keychain ~/.ssh/id_ed25519_<suffix>`
3. Verify: `ssh-add -l` should list all keys

### Wrong account used for push

1. Check `includeIf` directory in `~/.gitconfig` matches your repo location (trailing `/` matters)
2. Check `core.sshCommand` in the per-account gitconfig has `-o IdentitiesOnly=yes`
3. Verify: `git config core.sshCommand` from inside the repo

---

## References

- [Apple — Technical Note TN2449: UseKeychain and AddKeysToAgent](https://developer.apple.com/library/archive/technotes/tn2449/_index.html)
- [OpenSSH — `ssh_config(5)` (`UseKeychain`, `AddKeysToAgent`, `IdentitiesOnly`)](https://man.openbsd.org/ssh_config)
- [OpenSSH — `ssh-keygen(1)` (key generation, `-Y sign` for Git signing)](https://man.openbsd.org/ssh-keygen)
- [OpenSSH — `ssh-add(1)` (`--apple-use-keychain`)](https://man.openbsd.org/ssh-add)
- [Git — `git-config` (conditional includes, `core.sshCommand`, SSH signing)](https://git-scm.com/docs/git-config)
- [GitHub — Adding SSH keys to your account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- [GitHub — About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
- [GitHub — Managing multiple accounts](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-multiple-accounts)
