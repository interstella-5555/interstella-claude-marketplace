# Migration Guide: Switching Key Backends

How to migrate between 1Password and disk keys without downtime. Both key sets stay active on GitHub during transition — you can always roll back.

> **For Claude Code / AI assistants:** Follow the appropriate section based on migration direction. Keep old keys active until the new setup is fully verified.

---

## 1Password → Disk Keys

### Why migrate

- Eliminate Touch ID prompts entirely
- Keys work without 1Password running
- Silent commit signing (no popups, no biometric)
- Simpler setup with fewer moving parts

### Prerequisites

- Current 1Password setup is working (verify first with Repair Mode)
- macOS Keychain accessible (logged into your Mac)

### Steps

#### 1. Generate new keys on disk

1Password does not allow exporting private SSH keys — new keys must be generated.

```bash
ssh-keygen -t ed25519 -C "<email>" -f ~/.ssh/id_ed25519_<suffix>
# Repeat for each account
```

Use the same suffix as the existing setup (or ask user for new suffix preference).

#### 2. Add to macOS Keychain

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_<suffix>
# Enter passphrase — stored permanently in Keychain
# Repeat for each account
```

#### 3. Add new keys to GitHub

For each account, add the new public key as **both** Authentication Key and Signing Key. **Do NOT remove old 1Password keys yet.**

```bash
cat ~/.ssh/id_ed25519_<suffix>.pub | pbcopy
# → GitHub Settings → SSH and GPG keys → New SSH key
# Add as Authentication Key AND Signing Key
```

At this point, both old (1Password) and new (disk) keys are active on GitHub.

#### 4. Update SSH config

Replace 1Password agent with Keychain-based config:

**Before (1Password):**
```
Host *
  IdentityAgent ~/.1password/agent.sock
```

**After (disk keys):**
```
Host *
  AddKeysToAgent yes
  UseKeychain yes
```

#### 5. Update per-account gitconfigs

For each `~/.gitconfig-<suffix>`:

**Remove:**
```ini
[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
```

**Change `signingkey`** from literal key string to file path:

Before:
```ini
[user]
    signingkey = ssh-ed25519 AAAA...full-key-string...
```

After:
```ini
[user]
    signingkey = ~/.ssh/id_ed25519_<suffix>.pub
```

**Change `core.sshCommand`** to use new key path:

Before:
```ini
[core]
    sshCommand = ssh -i ~/.ssh/1password/<suffix>.pub -o IdentitiesOnly=yes
```

After:
```ini
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_<suffix> -o IdentitiesOnly=yes
```

Note: `sshCommand` now points to the **private key** (not `.pub`), because SSH reads it directly from disk.

#### 6. Verify

Run all checks:

```bash
# SSH auth (should work silently — no Touch ID, no passphrase prompt)
cd ~/code/some-repo && ssh -T git@github.com
cd ~/thorswap/some-repo && ssh -T git@github.com

# Commit signing (completely silent)
cd ~/code/some-repo && git commit --allow-empty -m "test disk key signing"
git log --show-signature -1

# Push
git push
# Check commit shows "Verified" on GitHub
```

#### 7. Remove old 1Password keys from GitHub

Only after everything works:
1. Go to https://github.com/settings/keys on each account
2. Remove the old 1Password SSH keys (both Authentication and Signing entries)

#### 8. Clean up (optional)

```bash
# Remove 1Password public keys directory
trash ~/.ssh/1password

# Remove agent symlink
trash ~/.1password/agent.sock

# Optionally disable 1Password SSH agent:
# 1Password → Settings → Developer → disable SSH Agent
```

---

## Disk Keys → 1Password

### Why migrate

- Private keys never on disk (stored in 1Password vault)
- Touch ID for commit signing
- Centralized key management through 1Password UI
- Keys backed up with 1Password account

### Prerequisites

- 1Password 8+ installed with active subscription
- SSH agent enabled in 1Password (Settings → Developer → Set Up SSH Agent)
- `op-ssh-sign` exists: `ls /Applications/1Password.app/Contents/MacOS/op-ssh-sign`

### Steps

#### 1. Create SSH keys in 1Password

For each account:
1. Open 1Password → **New Item** → **SSH Key**
2. **Generate New Key** → **Ed25519**
3. Name clearly: e.g. `GitHub Interstella`, `GitHub Thorswap`
4. Note which vault each key is in

#### 2. Configure 1Password agent

Create symlink if it doesn't exist:
```bash
mkdir -p ~/.1password
ln -s "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ~/.1password/agent.sock
```

Edit `~/.config/1Password/ssh/agent.toml` to include all vaults:
```toml
[[ssh-keys]]
vault = "Private"
authorize = "unlock"

[[ssh-keys]]
vault = "Work"
authorize = "unlock"
```

Verify agent sees keys:
```bash
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
```

#### 3. Save public keys to disk

```bash
mkdir -p ~/.ssh/1password
# Copy public key from 1Password (select key → Cmd+C) for each account:
echo "ssh-ed25519 AAAA...key..." > ~/.ssh/1password/<suffix>.pub
```

#### 4. Add new keys to GitHub

For each account, add the new 1Password public key as both Authentication and Signing key. **Do NOT remove old disk keys yet.**

#### 5. Update SSH config

**Before (disk keys):**
```
Host *
  AddKeysToAgent yes
  UseKeychain yes
```

**After (1Password):**
```
Host *
  IdentityAgent ~/.1password/agent.sock
```

#### 6. Update per-account gitconfigs

For each `~/.gitconfig-<suffix>`:

**Add:**
```ini
[gpg "ssh"]
    program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
```

**Change `signingkey`** from file path to literal key string:

Before:
```ini
[user]
    signingkey = ~/.ssh/id_ed25519_<suffix>.pub
```

After:
```ini
[user]
    signingkey = ssh-ed25519 AAAA...full-public-key-string...
```

**Change `core.sshCommand`** to use 1Password public key:

Before:
```ini
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519_<suffix> -o IdentitiesOnly=yes
```

After:
```ini
[core]
    sshCommand = ssh -i ~/.ssh/1password/<suffix>.pub -o IdentitiesOnly=yes
```

Note: with 1Password, `sshCommand` uses the `.pub` file. The agent matches by fingerprint and handles the private key internally.

#### 7. Verify

```bash
# SSH auth (Touch ID prompt expected)
cd ~/code/some-repo && ssh -T git@github.com
cd ~/thorswap/some-repo && ssh -T git@github.com

# Commit signing (Touch ID prompt)
cd ~/code/some-repo && git commit --allow-empty -m "test 1password signing"
git log --show-signature -1
```

#### 8. Remove old disk keys from GitHub

Only after everything works. Remove old SSH keys from GitHub settings on each account.

#### 9. Backup old disk keys

```bash
mkdir -p ~/.ssh/backup
mv ~/.ssh/id_ed25519_<suffix> ~/.ssh/backup/
mv ~/.ssh/id_ed25519_<suffix>.pub ~/.ssh/backup/
# Repeat for each account
```

> To permanently remove: `trash ~/.ssh/backup/` (moves to macOS Trash — still recoverable).

---

## Rollback

If migration fails at any point:

1. **Both key sets are on GitHub** — the old setup still works
2. Revert `~/.ssh/config` to the old version
3. Revert per-account gitconfigs
4. Test with old keys

Only after full verification should you remove old keys from GitHub and clean up.
