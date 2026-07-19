#!/bin/sh
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
wt_name=$(echo "$input" | jq -r '.worktree.name // empty')
wt_branch=$(echo "$input" | jq -r '.worktree.branch // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
model="${model%% *}"  # family only: "Opus 4.8" -> "Opus"
effort=$(echo "$input" | jq -r '.effort.level // empty')

sep=" · "
parts=""

# Git branch — worktree from JSON, otherwise from .git/HEAD (no subprocess)
if [ -n "$wt_branch" ]; then
  parts="⎇  worktree: ${wt_branch}"
  branch="$wt_branch"
elif [ -n "$wt_name" ]; then
  parts="⎇  worktree: ${wt_name}"
  branch="$wt_name"
else
  # Walk up directory tree to find .git (handles monorepos / subdirs / worktrees)
  dir="$cwd"
  branch=""
  is_worktree=""
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -e "$dir/.git" ]; then
      git_path="$dir/.git"
      # Worktree: .git is a file pointing to the real gitdir
      if [ -f "$git_path" ]; then
        is_worktree="1"
        gitdir=$(sed -n 's/^gitdir: //p' "$git_path")
        # Resolve relative paths
        case "$gitdir" in
          /*) : ;;
          *) gitdir="$dir/$gitdir" ;;
        esac
        head_file="$gitdir/HEAD"
      else
        head_file="$git_path/HEAD"
      fi
      if [ -f "$head_file" ]; then
        head=$(cat "$head_file")
        case "$head" in
          ref:*) branch="${head#ref: refs/heads/}" ;;
          *) branch="${head%${head#???????}}" ;;
        esac
      fi
      break
    fi
    dir="${dir%/*}"
  done
  if [ -n "$branch" ]; then
    if [ -n "$is_worktree" ]; then
      parts="⎇  worktree: ${branch}"
    else
      parts="⎇  ${branch}"
    fi
  fi
fi

# PR detection — skip main/master, cache-first, background refresh
if [ -n "$branch" ] && [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
  branch_hash=$(printf '%s' "$branch" | md5)
  cache_file="/tmp/gh-pr-cache-${branch_hash}"

  needs_refresh=""
  if [ ! -f "$cache_file" ]; then
    needs_refresh="1"
  else
    cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    age=$(( $(date +%s) - cache_mtime ))
    [ "$age" -gt 60 ] && needs_refresh="1"
  fi

  if [ -n "$needs_refresh" ]; then
    (gh pr view "$branch" --json number,url,state,isDraft 2>/dev/null > "$cache_file.tmp" && mv "$cache_file.tmp" "$cache_file" || rm -f "$cache_file.tmp") &
  fi

  if [ -f "$cache_file" ] && [ -s "$cache_file" ]; then
    pr_state=$(jq -r '.state // empty' "$cache_file" 2>/dev/null)
    pr_number=$(jq -r '.number // empty' "$cache_file" 2>/dev/null)
    pr_url=$(jq -r '.url // empty' "$cache_file" 2>/dev/null)
    pr_draft=$(jq -r '.isDraft // empty' "$cache_file" 2>/dev/null)
    if [ -n "$pr_number" ] && [ -n "$pr_url" ]; then
      pr_suffix=""
      if [ "$pr_draft" = "true" ]; then
        pr_suffix=" (draft)"
      elif [ "$pr_state" = "MERGED" ]; then
        pr_suffix=" (merged)"
      elif [ "$pr_state" = "CLOSED" ]; then
        pr_suffix=" (closed)"
      fi
      pr_link="\033]8;;${pr_url}\007PR #${pr_number}${pr_suffix}\033]8;;\007"
      parts="${parts}${sep}${pr_link}"
    fi
  fi
fi

# Context usage
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 50 ]; then
    ctx="\033[1;31m${used_int}% context\033[0m"
  elif [ "$used_int" -ge 30 ]; then
    ctx="\033[33m${used_int}% context\033[0m"
  else
    ctx="${used_int}% context"
  fi
  if [ -n "$parts" ]; then
    parts="${parts}${sep}${ctx}"
  else
    parts="${ctx}"
  fi
fi

# Model + reasoning effort (effort absent when the model doesn't support it)
if [ -n "$model" ]; then
  seg="$model"
  [ -n "$effort" ] && seg="${seg} ${effort}"
  if [ -n "$parts" ]; then
    parts="${parts}${sep}${seg}"
  else
    parts="${seg}"
  fi
fi

printf '%b' "$parts"
