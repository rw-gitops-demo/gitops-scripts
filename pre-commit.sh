#!/usr/bin/env bash
. "$(dirname -- "$0")/utils.sh"

BUILD_KEY="pre-commit"
PATCH_FILE="working-tree.patch"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

function main {
  move_unstaged_changes_to_patch_file

  local git_cached_files
  git_cached_files=$(git diff --cached --name-only)

  if [ "$git_cached_files" ]; then
    echo "${BOLD}Validating the updated manifests...${NORMAL}"
    build_manifests "$BUILD_KEY"
    validate_manifests "$BUILD_KEY"
  fi
}

function move_unstaged_changes_to_patch_file {
  git diff > "$PATCH_FILE"
  git checkout -- .
}

function cleanup {
  exit_code=$?
  if [ -f "$PATCH_FILE" ]; then
    git apply "$PATCH_FILE" 2> /dev/null || true
    rm "$PATCH_FILE"
  fi
  exit $exit_code
}

trap cleanup ERR EXIT SIGINT SIGHUP

main
