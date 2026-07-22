# Switch the current repo to its default branch (main/master) and fast-forward to origin.
main() {
  # Defined inside main() so it's always present when called — a long-lived
  # shell that sourced an older copy of this file (before this helper existed)
  # would otherwise hit "command not found: _main_warn_dirty".
  _main_warn_dirty() {
    local modified untracked
    modified=$(git diff --name-only HEAD 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [ "$modified" -gt 0 ] || [ "$untracked" -gt 0 ]; then
      echo "Note: working tree has $modified modified, $untracked untracked file(s)."
    fi
  }

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a git repository."
    return 1
  fi

  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [ -z "$default_branch" ]; then
    if git show-ref --verify --quiet refs/heads/main; then
      default_branch=main
    elif git show-ref --verify --quiet refs/heads/master; then
      default_branch=master
    else
      echo "Could not determine default branch."
      echo "Recommendation: run 'git remote set-head origin -a' to detect it."
      return 1
    fi
  fi

  echo "Fetching origin..."
  if ! git fetch origin --prune; then
    echo "Failed to fetch from origin."
    return 1
  fi

  local current_branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  if [ "$current_branch" = "$default_branch" ]; then
    if ! git merge --ff-only "origin/$default_branch"; then
      echo
      echo "Could not fast-forward $default_branch."
      echo "Recommendation: stash conflicting changes ('git stash push -m wip'), or check for divergence ('git log --oneline --graph $default_branch origin/$default_branch')."
      return 1
    fi
    echo "Already on $default_branch, fast-forwarded to origin/$default_branch. OK."
    _main_warn_dirty
    return 0
  fi

  # If the default branch is already checked out in another worktree, we can't
  # switch to it here - create a fresh scratch branch from origin/<default> instead.
  local current_wt other_wt
  current_wt=$(git rev-parse --show-toplevel)
  other_wt=$(git worktree list --porcelain | awk -v b="refs/heads/$default_branch" '
    /^worktree / { wt = $2 }
    $0 == "branch " b { print wt; exit }
  ')

  if [ -n "$other_wt" ] && [ "$other_wt" != "$current_wt" ]; then
    local scratch_branch="scratch/${default_branch}-$(date +%Y%m%d-%H%M%S)"
    if ! git switch -c "$scratch_branch" "origin/$default_branch"; then
      echo
      echo "Failed to create scratch branch from origin/$default_branch."
      echo "Recommendation: stash conflicting changes ('git stash push -m wip') and try again."
      return 1
    fi
    echo "$default_branch is checked out in another worktree ($other_wt)."
    echo "Created scratch branch '$scratch_branch' from origin/$default_branch and switched to it. OK."
    _main_warn_dirty
    return 0
  fi

  if ! git switch "$default_branch"; then
    echo
    echo "Failed to switch to $default_branch."
    echo "Recommendation: stash conflicting changes ('git stash push -m wip') and try again."
    return 1
  fi

  if ! git merge --ff-only "origin/$default_branch"; then
    echo
    echo "Switched to $default_branch but could not fast-forward to origin/$default_branch."
    echo "Recommendation: stash conflicting changes ('git stash push -m wip'), or run 'git pull --rebase' if local has diverged."
    return 1
  fi

  echo "Switched from $current_branch to $default_branch and fast-forwarded to origin/$default_branch. OK."
  _main_warn_dirty
}
