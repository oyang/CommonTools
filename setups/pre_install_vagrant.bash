#!/bin/bash
CURRENT_DIR=$(dirname "${BASH_SOURCE[0]}")
source "${CURRENT_DIR}/common.bash"

VBOX_VER="5.0.20"
VBOX_RELEASE="106931"
VBOX_DOWNLOAD_URL="http://download.virtualbox.org/virtualbox/${VBOX_VER}/VirtualBox-${VBOX_VER}-${VBOX_RELEASE}-OSX.dmg"
VBOX_DOWNLOAD_DEST="${HOME}/Downloads/Virtualbox-${VBOX_VER}-${VBOX_RELEASE}.dmg"
VBOX_MOUNT_PATH="/Volumes/VirtualBox"

VAGRANT_VER="1.8.1"
VAGRANT_DOWNLOAD_URL="https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/vagrant_${VAGRANT_VER}.dmg"
VAGRANT_DOWNLOAD_DEST="${HOME}/Downloads/Vagrant-${VAGRANT_VER}.dmg"
VAGRANT_MOUNT_PATH="/Volumes/Vagrant"

function download() {
  local name="$1"
  local download_url="$2"
  local download_dest="$3"

  if [ ! -d $(dirname "${download_dest}") ]; then
    logerror "Not a valid download dest: ${download_dest}!"
    exit 1
  fi

  loginfo "Downloading $name: ${download_url} ..."
  loginfo "curl -C - -o ${name} ${download_url} -O ${download_dest}"
  curl -C - -o "${download_dest}" -O ${download_url}
  loginfo "Download Complete."
}

function install_dmg() {
  local name="$1"
  local download_dest="$2"
  local mount_path="$3"
  local package_path="${mount_path}/${name}.pkg"

  if [ -f ${download_dest} ];then
    hdiutil mount -quiet -nobrowse -readonly -noidme ${download_dest}
    if [ -f ${package_path} ];then
      /usr/sbin/installer -pkg ${package_path} -target /
    else
      logerror "Can not find the package path: ${package_path}!"
    fi
  else
    logerror "Can not find the download file: ${download_dest}!"
  fi

  if [ -d ${mount_path} ];then
    hdiutil eject -quiet ${mount_path}
  else
    logwarn "Mount_path is invalid: ${mount_path}!"
  fi
}

function install_xcode() {
  loginfo "Installing Xcode Command Tool ..."

  if xcode-select -v >/dev/null; then
    loginfo "Found existing Xcode in your system, no more action!"
  else
    xcode-select --install
  fi

  loginfo "Done."
}

function install_virtualbox() {
  loginfo "Installing Virtualbox($VBOX_VER) ..."
  local continue_install="false"

  if VBoxManage -v >/dev/null; then
    local current_ver=$(VBoxManage -v|sed -e 's/[a-zA-Z].*$//')
    vercomp ${current_ver} ${VBOX_VER}

    if [ "2" -eq $? ]; then
      continue_install="true"
      logwarn "You're running a lower version virtualbox:(${current_ver}) than required:(${VBOX_VER})!"
    else
      loginfo "Found existing Virtualbox($current_ver) in your system, no more action!"
    fi
  else
    continue_install="true"
  fi

  if [ "true" = "${continue_install}" ]; then
    download VirtualBox ${VBOX_DOWNLOAD_URL} ${VBOX_DOWNLOAD_DEST}
    install_dmg VirtualBox ${VBOX_DOWNLOAD_DEST} ${VBOX_MOUNT_PATH}
  fi

  loginfo "Done."
}

function install_vagrant() {
  loginfo "Installing Vagrant(${VAGRANT_VER}) tool ..."
  local continue_install="false"

  if vagrant -v >/dev/null; then
    local current_ver=$(vagrant -v|awk '{print $2}')
    vercomp ${current_ver} ${VAGRANT_VER}

    if [ "2" -eq $? ]; then
      continue_install="true"
      logwarn "You're running a lower version vagrant:(${current_ver}) than required:(${VAGRANT_VER})!"
    else
      loginfo "Found existing Vagrant($current_ver) in your system, no more action!"
    fi
  else
    continue_install="true"
  fi

  if [ "true" = "${continue_install}" ]; then
    download Vagrant ${VAGRANT_DOWNLOAD_URL} ${VAGRANT_DOWNLOAD_DEST}
    install_dmg Vagrant ${VAGRANT_DOWNLOAD_DEST} ${VAGRANT_MOUNT_PATH}
  fi

  loginfo "Done."
}

function install_vagrant_plugins() {
  loginfo "Install Vagrant plugins ..."
  local existing_list=$(vagrant plugin list)
  local required_plugins=("vagrant-cachier")

  for j in ${required_plugins[@]}; do
    if [[ ! "${existing_list}" =~ "$j" ]]; then
      vagrant plugin install $j
    else
      logwarn "Vagrant plugin $j already be installed!"
    fi
  done

  loginfo "Done."
}

function main() {
  if [ $(whoami) != "root" ]; then
    logerror "You must run this script as sudo user!"
    exit 1
  fi

  install_xcode
  install_virtualbox
  install_vagrant
  install_vagrant_plugins
}

main
