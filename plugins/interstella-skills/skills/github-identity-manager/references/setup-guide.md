# Multi-Account GitHub SSH + Commit Signing with 1Password

Complete guide for setting up multiple GitHub accounts on one machine with:
- **SSH authentication** via 1Password SSH agent (no keys on disk)
- **Commit signing** via 1Password `op-ssh-sign` (Touch ID)
- **Automatic account switching** based on directory (`~/work/` vs `~/personal/`)
- **No Host aliases** — everything uses `github.com`

> **For Claude Code / AI assistants:** This document is a complete setup guide. If the user asks you to set this up, follow each section in order. Adapt directory paths and account names to the user's setup. If they don't have separate directories per GitHub account, suggest creating them first (e.g. `~/work/` and `~/personal/`).

---

## Prerequisites

- macOS (tested on macOS 15+)
- [1Password 8+](https://1password.com/downloads/mac) with SSH agent enabled
- [Git 2.36+](https://git-scm.com/) (for `includeIf` and `core.sshCommand` support)
- [GitHub CLI](https://cli.github.com/) (`gh`) — optional, for automation
- Two (or more) GitHub accounts

### Verify git version

```bash
git --version
# Needs 2.36+ for core.sshCommand with includeIf
```

---

## Step 1: Generate SSH keys in 1Password

For **each** GitHub account, create a dedicated SSH key in 1Password:

1. Open 1Password → **New Item** → **SSH Key**
2. **Generate New Key** → **Ed25519**
3. Name it clearly: `GitHub <AccountName>` (e.g. `GitHub Personal`, `GitHub Work`)
4. Save

> **Important:** Note which 1Password vault each key lives in. Keys in vaults other than "Private" need explicit configuration in Step 3.

Ref: [1Password — Manage SSH Keys](https://developer.1password.com/docs/ssh/manage-keys/)

---

## Step 2: Enable 1Password SSH agent

1. Open 1Password → **Settings** → **Developer**
2. Click **Set Up SSH Agent**
3. Enable **Display key names when authorizing connections** (helps identify which key is being used)
4. Under **General** → enable **Keep 1Password in the menu bar** and **Start at login**

Ref: [1Password — Turn on the SSH agent](https://developer.1password.com/docs/ssh/get-started/#step-3-turn-on-the-1password-ssh-agent)

---

## Step 3: Configure 1Password agent for multiple vaults

If your SSH keys are in different vaults (e.g. "Private" and "Work"), edit the agent config:

**File: `~/.config/1Password/ssh/agent.toml`**

```toml
[[ssh-keys]]
vault = "Private"

[[ssh-keys]]
vault = "Work"
```

Ref: [1Password — SSH agent config file](https://developer.1password.com/docs/ssh/agent/config/)

Create the recommended symlink for a cleaner agent socket path ([1Password — Configure your SSH client](https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client)):

```bash
mkdir -p ~/.1password
ln -s "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ~/.1password/agent.sock
```

> The `2BUA8C4S2C.com.1password` path is Apple's [macOS App Group Container](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups) identifier for 1Password. The symlink is [recommended by 1Password](https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client) for convenience.

Verify the agent sees all keys:

```bash
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
# Should list all your GitHub SSH keys
```

---

## Step 4: Save public keys to disk

Git's [`core.sshCommand`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-coresshCommand) needs a public key file to tell the 1Password agent which key to offer. The agent matches by public key fingerprint and handles the private key internally.

```bash
mkdir -p ~/.ssh/1password

# Copy public key from 1Password for each account
# (1Password → select key → Cmd+C copies public key)
echo "ssh-ed25519 AAAA...your-personal-key..." > ~/.ssh/1password/personal.pub
echo "ssh-ed25519 AAAA...your-work-key..." > ~/.ssh/1password/work.pub
```

> **Note:** These are public keys — not secrets. They never change (derived mathematically from the private key). Safe to keep on disk.

How this works with the SSH agent: when `ssh -i path/to/key.pub` is used and an agent is active, [OpenSSH reads the public key from the file and asks the agent to sign with the matching private key](https://man.openbsd.org/ssh#-i). The private key never leaves 1Password.

---

## Step 5: Configure SSH

**File: `~/.ssh/config`** ([`ssh_config(5)` man page](https://man.openbsd.org/ssh_config))

```
# 1Password SSH agent — all connections use this
Host *
  IdentityAgent ~/.1password/agent.sock
```

That's it. No Host aliases, no per-host IdentityFile. Git handles key selection via `core.sshCommand` (next step).

The [`IdentityAgent`](https://man.openbsd.org/ssh_config#IdentityAgent) directive tells SSH which agent socket to use, overriding `SSH_AUTH_SOCK`. This is the [method recommended by 1Password](https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client).

---

## Step 6: Configure Git

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
[includeIf "gitdir:~/personal/"]
    path = ~/.gitconfig-personal
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

Ref: [Git — Conditional Includes (`includeIf`)](https://git-scm.com/docs/git-config#_conditional_includes)

### Per-account configs

**File: `~/.gitconfig-personal`**

```ini
[user]
    name = Your Name
    email = your-personal-github-noreply@users.noreply.github.com
    signingkey = ssh-ed25519 AAAA...your-personal-key...
[gpg]
    format = ssh
[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
[core]
    sshCommand = ssh -i ~/.ssh/1password/personal.pub -o IdentitiesOnly=yes
```

**File: `~/.gitconfig-work`**

```ini
[user]
    name = Your Work Name
    email = your-work-github-noreply@users.noreply.github.com
    signingkey = ssh-ed25519 AAAA...your-work-key...
[gpg]
    format = ssh
[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
[core]
    sshCommand = ssh -i ~/.ssh/1password/work.pub -o IdentitiesOnly=yes
```

### How it works

- [`includeIf "gitdir:"`](https://git-scm.com/docs/git-config#_conditional_includes) — git loads the matching config file based on repo directory
- [`core.sshCommand`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-coresshCommand) — tells git to use `ssh -i <public-key>` which makes the 1Password agent offer only the matching key
- [`-o IdentitiesOnly=yes`](https://man.openbsd.org/ssh_config#IdentitiesOnly) — prevents the agent from offering other keys (avoids GitHub picking the wrong account)
- [`gpg.ssh.program`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgsshprogram) — 1Password's `op-ssh-sign` handles commit signing with Touch ID ([1Password — Sign Git commits](https://developer.1password.com/docs/ssh/git-commit-signing/))
- [`user.signingkey`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-usersigningKey) — tells `op-ssh-sign` which key to sign with

---

## Step 7: Add keys to GitHub

For **each** GitHub account, add the corresponding SSH key as **both** Authentication and Signing key:

1. Log into the GitHub account
2. Go to https://github.com/settings/ssh/new
3. Add the public key as **Authentication Key** (for push/pull/clone)
4. Add the same public key again as **Signing Key** (for verified commits)

Ref: [GitHub — Adding a new SSH key to your account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

Ref: [GitHub — About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification#ssh-commit-signature-verification)

---

## Step 8: Fix existing remotes

If any repos use HTTPS or Host aliases, convert them to plain SSH:

```bash
# Fix HTTPS → SSH
git remote set-url origin git@github.com:org/repo.git

# Fix Host alias → github.com
# e.g. git@github-work:org/repo.git → git@github.com:org/repo.git
git remote set-url origin git@github.com:org/repo.git
```

Bulk fix all repos in a directory:

```bash
for dir in ~/work/*/; do
  [ -d "$dir/.git" ] || continue
  url=$(git -C "$dir" remote get-url origin 2>/dev/null)
  # Fix HTTPS
  if echo "$url" | grep -q "https://github.com/"; then
    new_url=$(echo "$url" | sed 's|https://github.com/|git@github.com:|')
    git -C "$dir" remote set-url origin "$new_url"
    echo "Fixed: $(basename $dir)"
  fi
done
```

Ref: [git-remote docs](https://git-scm.com/docs/git-remote)

---

## Step 9: Verify

```bash
# Test SSH auth (should show correct account name)
cd ~/personal/some-repo && ssh -T git@github.com
# → Hi personal-account! You've successfully authenticated...

cd ~/work/some-repo && ssh -T git@github.com
# → Hi work-account! You've successfully authenticated...

# Test commit signing (should trigger Touch ID)
cd ~/personal/some-repo && git commit --allow-empty -m "test signing"
git log --show-signature -1
# → Good "git" signature with ED25519 key...

# Check on GitHub
git push
# Commit should show "Verified" badge on GitHub
```

---

## Optional: Clean up previous signing setup

After switching to 1Password, you can remove any previous GPG or SSH signing infrastructure. This setup fully replaces GPG-based commit signing — 1Password handles both SSH auth and commit signing via [`op-ssh-sign`](https://developer.1password.com/docs/ssh/git-commit-signing/).

Things to check and clean up:

- **GPG installation** (homebrew): `brew uninstall gnupg` — removes GnuPG and its dependencies ([Homebrew docs](https://docs.brew.sh/FAQ#how-do-i-uninstall-a-formula))
- **GPG data directory**: `rm -rf ~/.gnupg` — contains your old GPG keyring and config
- **GPG shell config** — remove `GPG_TTY=$(tty)` and `export GPG_TTY` from `~/.zshrc` / `~/.bashrc` (only needed for GPG pinentry, not SSH signing)
- **GPG Tools launch agents** (macOS) — if you had [GPG Suite](https://gpgtools.org/) installed:
  ```bash
  launchctl remove org.gpgtools.macgpg2.shutdown-gpg-agent 2>/dev/null
  launchctl remove org.gpgtools.updater 2>/dev/null
  launchctl remove org.gpgtools.macgpg2.fix 2>/dev/null
  ```
- **Old SSH keys on disk** — if you had `~/.ssh/id_ed25519_github` or similar keys that were only used for GitHub auth/signing, you can delete them. Keep keys used for other servers (VPS, etc.)
- **Old keys on GitHub** — go to https://github.com/settings/keys and **manually review and delete** any keys you no longer need: old GPG keys, old SSH authentication keys, and old SSH signing keys. Only keep the new 1Password keys you just added. **Do this for each GitHub account.**
- **Old `~/.ssh/config` Host aliases** — if you had `Host github-work` style aliases for multi-account SSH, they're no longer needed (replaced by `core.sshCommand` in gitconfig)
- **Old `~/.gitconfig` GPG settings** — remove `gpg.program`, any `gpg.format = openpgp` entries. The per-directory gitconfig files handle `gpg.format = ssh` now
- **Misc `~/.ssh/` cleanup** — remove `known_hosts.old` (stale backup), any old agent socket directories, `.DS_Store` files. Keep `known_hosts` (needed for SSH host verification)

---

## Troubleshooting

### "Permission denied (publickey)" on push/pull

1. Check agent has the key: `SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l`
2. Check correct key is offered: `GIT_SSH_COMMAND="ssh -v" git fetch 2>&1 | grep Offering`
3. Check the key is added to GitHub as **Authentication Key**
4. Check `core.sshCommand` is set: `git config core.sshCommand`

Ref: [GitHub — Troubleshooting SSH](https://docs.github.com/en/authentication/troubleshooting-ssh)

### Commit shows "Unverified" on GitHub

1. Check the key is added to GitHub as **Signing Key** (not just Authentication)
2. Check `git config user.email` matches the email on your GitHub account (including `@users.noreply.github.com`)
3. Test locally: `git log --show-signature -1`

Ref: [GitHub — Troubleshooting commit signature verification](https://docs.github.com/en/authentication/troubleshooting-commit-signature-verification)

### 1Password popup shows wrong key

The `core.sshCommand` with `-i <key>.pub -o IdentitiesOnly=yes` should prevent this. If it still happens:
1. Verify `git config core.sshCommand` shows the correct key path
2. Verify `git config user.signingkey` matches the same key
3. Check you're in the right directory (the `includeIf "gitdir:"` must match)

### SSH works but signing doesn't

1. Verify `op-ssh-sign` exists: `ls /Applications/1Password.app/Contents/MacOS/op-ssh-sign`
2. Check git config: `git config gpg.ssh.program` should show the path above
3. Check `git config commit.gpgsign` is `true`

Ref: [1Password — Troubleshooting Git commit signing](https://developer.1password.com/docs/ssh/git-commit-signing/#troubleshooting)

---

## References

- [1Password — SSH Agent: Get Started](https://developer.1password.com/docs/ssh/get-started/) — full setup walkthrough
- [1Password — SSH Agent: Advanced Config](https://developer.1password.com/docs/ssh/agent/advanced/) — gradual migration, per-host config
- [1Password — SSH Agent Config File](https://developer.1password.com/docs/ssh/agent/config/) — `agent.toml` vault/key filtering
- [1Password — Sign Git Commits with SSH](https://developer.1password.com/docs/ssh/git-commit-signing/) — `op-ssh-sign` setup
- [Apple — App Group Containers](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups) — explains the `2BUA8C4S2C` path
- [Git — `git-config` (conditional includes, `core.sshCommand`, signing)](https://git-scm.com/docs/git-config)
- [Git — Conditional Includes (`includeIf`)](https://git-scm.com/docs/git-config#_conditional_includes)
- [OpenSSH — `ssh_config(5)` (`IdentityAgent`, `IdentitiesOnly`, `-i`)](https://man.openbsd.org/ssh_config)
- [OpenSSH — `ssh(1)` (`-i` flag behavior with agents)](https://man.openbsd.org/ssh#-i)
- [GitHub — Adding SSH keys to your account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- [GitHub — About commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
- [GitHub — Managing multiple accounts](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-your-personal-account/managing-multiple-accounts)
- [GitHub — Troubleshooting SSH](https://docs.github.com/en/authentication/troubleshooting-ssh)
