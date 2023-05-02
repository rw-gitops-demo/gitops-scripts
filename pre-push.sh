#!/usr/bin/env bash
. "$(dirname -- "$0")/utils.sh"

BOLD=$(tput bold)
NORMAL=$(tput sgr0)

function main {
  diff_manifests

  echo -e "\n${BOLD}Do you want to push these changes?${NORMAL}"
  echo -e "  Only 'yes' will be accepted to approve.\n"
  read -r -p "${BOLD}Enter a value: ${NORMAL}" yn

  case $yn in
  	yes ) echo "Pushing changes...";;
  	* )
  		exit 1;;
  esac
}

exec < /dev/tty

main
