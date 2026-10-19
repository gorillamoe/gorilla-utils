#!/usr/bin/env bash

set -euo pipefail

if ! command -v fd &> /dev/null; then
    echo "Error: fd command not found. Please install fd-find."
    exit 1
fi

current_dir="$(pwd)"
base_dir="${1:-$current_dir}"

if [ ! -d "$base_dir" ]; then
    echo "Error: $base_dir is not a directory"
    exit 1
fi

if [ ! -r "$base_dir" ]; then
    echo "Error: $base_dir is not readable"
    exit 1
fi

if [ ! -x "$base_dir" ]; then
    echo "Error: $base_dir is not executable"
    exit 1
fi

if [ "$current_dir" != "$base_dir" ]; then
  cd "$base_dir" || (echo "Failed to cd to $base_dir" && exit 2);
fi

directories=$(fd -t d -d 1 .)

for d in ${directories}; do
  d="${d%/}"
  echo "Processing directory: $d"
  cd "$d" || (echo "Failed to cd into $d" && exit 3);
  if [[ ! -d ".git" ]]; then
    echo "Skipping $d, not a git repo";
    cd ../ || (echo "Failed to cd back to parent directory" && exit 3);
    continue;
  fi;
  remote_url="$(git remote -v | head -1 | sed -n 's/.*bitbucket.org/git@ssh.bitbucket.org/p' | uniq)"
  if [ -z "$remote_url" ]; then
    echo "No Bitbucket remote found for $d, skipping";
    cd ../ || (echo "Failed to cd back to parent directory" && exit 3);
    continue;
  fi;
  git remote set-url origin \
    "${remote_url}" || \
    (echo "Failed to set remote URL for $d; skipping.." && (cd ../ || (echo "Failed to cd back to parent directory" && exit 3)) && exit 5);
  cd ../ || (echo "Failed to cd back to parent directory" && exit 3);
done;

cd "$current_dir" || (echo "Failed to cd back to original directory" && exit 4);
