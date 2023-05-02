#!/usr/bin/env bash

BUILD_DIR="./build"
CACHE_DIR="./cache"
MANIFEST_PATH_PATTERN="**/envs/*"
CRDS_SCHEMA_LOCATION="https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

function build_manifests {
  local build_key="${1:-"HEAD"}"

  rm -rf "$BUILD_DIR/${build_key:?}"

  for envpath in $MANIFEST_PATH_PATTERN; do
    local build_dir env
    if ! [ -d "$envpath" ]; then continue; fi
    if [[ "$envpath" == *"base"* ]]; then continue; fi
    env=$(basename "$envpath")
    build_dir="$BUILD_DIR/$build_key/$env"
    mkdir -p "$build_dir"

    kustomize build "$envpath" -o "$build_dir" &> /dev/null
    if [ $? -ne 0 ]; then
      echo "Kustomize build failed for $env environment."
    fi
  done
}

function build_manifests_for_ref {
  local ref="${1:-"origin/main"}"

  if [[ "$ref" == "HEAD" ]]; then
    build_manifests "$ref"
  else
    git checkout "$ref" --quiet
    build_manifests "$ref"
    git switch - --quiet
  fi
}

function validate_manifests {
  local build_key="${1:-"HEAD"}"

  mkdir -p "$CACHE_DIR"
  kubeconform -summary -cache "$CACHE_DIR" -schema-location default -schema-location "$CRDS_SCHEMA_LOCATION" -skip CustomResourceDefinition "$BUILD_DIR/$build_key"
}

function diff_manifests {
  local ref_a="${1:-"origin/main"}"
  local ref_b="${2:-"HEAD"}"

  local affected_envs=()

  echo -e "${BOLD}Calculating the diff between ${ref_a} and ${ref_b} for each environment...${NORMAL}"

  check_for_local_changes
  build_manifests_for_ref "$ref_a"
  build_manifests_for_ref "$ref_b"

  for envpath in $MANIFEST_PATH_PATTERN; do
    local env dir_a dir_b
    env="$(basename "$envpath")"

    if [[ " ${affected_envs[*]} " =~ " ${env} " ]]; then continue; fi

    dir_a="$BUILD_DIR/$ref_a/$env"
    dir_b="$BUILD_DIR/$ref_b/$env"
    mkdir -p "$dir_a"
    mkdir -p "$dir_b"
    set +e
    diff=$(git diff --no-index --name-only "$dir_a" "$dir_b")
    set -e
    if [ -n "$diff" ]
    then
      affected_envs+=("$env")
    fi
  done

  if [ ${#affected_envs[@]} -eq 0 ]; then
    echo -e "No environments have changes between $ref_a and $ref_b."
  else
    for env in "${affected_envs[@]}"; do
      echo -e "\n-------------------------- ${BOLD}${env}${NORMAL} --------------------------\n"
      git diff --no-index "$BUILD_DIR/$ref_a/${env}" "$BUILD_DIR/$ref_b/${env}" || true
    done
    echo -e "\n#####################################################################"
    echo -e "---------------------------------------------------------------------\n"
    echo -e "${BOLD}The following environments have changes between $ref_a and $ref_b:${NORMAL}"
    echo "${affected_envs[@]}"
  fi
}

function check_for_local_changes {
  local git_diff
  git_diff=$(git diff --name-only HEAD)

  if [ "$git_diff" ]; then
    echo -e "Unable to calculate the diff because of uncommitted changes.\nPlease commit your changes or stash them."
    exit 1
  fi
}
