#!/bin/bash
CURRENT_DIR=$(dirname "${BASH_SOURCE[0]}")
source "${CURRENT_DIR}/common.bash"

BASH_IT="$HOME/.bash_it"

# install homebrew first http://brew.sh/
function install_brew() {
  if ! brew -v >/dev/null 2>&1 ; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  else
    echo -e "${Warning} Homebrew already be installed!"
  fi
}

# install wget, curl, git
function install_brew_package() {
  local install_list=(git wget curl the_silver_searcher fzf)

  for i in ${install_list[@]}; do
    brew install $i
  done
}

# install Bash-it https://github.com/Bash-it/bash-it
function install_bashit() {
  if ! [ -d "${BASH_IT}" ] ; then
      git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
      source ~/.bash_it/install.sh
  else
    echo -e "${Warning} Bash-it already be installed!"
  fi
}

# enable bashit package
function install_bashit_package() {
  # fasd plugin make you move fast between directory
  source $BASH_IT/bash_it.sh
  bash-it enable plugin fasd

  # to make the enabled plugin take effect
  source ~/.bashrc
}

function main() {
  install_brew
  install_brew_package

  install_bashit
  install_bashit_package
}

main
