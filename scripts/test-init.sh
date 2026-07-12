#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
repo_dir="$project_root/playground/init-repo"

cd "$project_root"

echo "==> Building ugit escript"
gleam export escript

mkdir -p "$repo_dir"
cp "$project_root/ugit" "$repo_dir/ugit"
chmod +x "$repo_dir/ugit"

echo "==> Prepared manual test repository"
echo "cd $repo_dir"
echo "./ugit init"
