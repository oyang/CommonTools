#!/bin/bash
RED='\033[1;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # no color
warn="${YELLOW}Warning:${NC}"
error="${RED}Error:${NC}"
info="${GREEN}Info:${NC}"

function log() {
  local level="info"
  local message=""

  if [ -n "$1" ]; then
    level=$1
  fi

  prefix=${!level}
  shift
  echo -e "$prefix" $*
}

function loginfo() {
  log info $1
}

function logwarn() {
  log warn $1
}

function logerror() {
  log error $1
}

vercomp () {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done

    return 0
}
