#!/bin/bash
PHP_NAME="php"
PHP_VER=""
LICENSE="PHP"
VENDOR="oyang"
BUILD_DIR="/tmp/build_php"
ALT_INSTALL_ROOT="${BUILD_DIR}/INSTALL_ROOT"
PHP_SRC_DIR=""

function init_setup() {
  mkdir -p "${ALT_INSTALL_ROOT}"
}

function download_php_src() {
  if [ ! -d ${ALT_INSTALL_ROOT} ]; then
    init_setup
  fi

  wget -c -O "${BUILD_DIR}/PHP-${PHP_VER}.zip" "https://github.com/php/php-src/archive/PHP-${PHP_VER}.zip"
}

function unzip_zipped_php() {
  unzip -d "${BUILD_DIR}" "${BUILD_DIR}/PHP-${PHP_VER}.zip"
}

function build_php_src() {
  # Check the php src download dependencies
  if [ ! -d "${PHP_SRC_DIR}" ]; then
    echo -n "There is no PHP source dir, continue to run download? [Y/n]"
    read answer
    if [[ "$answer" =~ [Yy] ]]; then
      download_php_src
      unzip_zipped_php
    else
      return 1
    fi
  fi

  local OLD_DIR=$(pwd)
  cd ${PHP_SRC_DIR}

  ./buildconf --force

  ./configure \
    --enable-mbstring \
    --without-pear \
    --with-curl \
    --with-openssl \
    --with-imap \
    --with-imap-ssl \
    --with-zlib \
    --enable-zip \
    --enable-soap \
    --with-libdir=lib64 \
    --with-gd \
    --enable-bcmath \
    --with-ldap \
    --with-ldap-sasl \
    --with-kerberos  \
    --with-mysql \
    --with-apxs2 \
    --with-mysqli \
    --with-mcrypt
  make clean
  make -j2

  cd ${OLD_DIR}
}

function pre_install_php() {
  mkdir -p "${ALT_INSTALL_ROOT}/etc/httpd/conf"
  grep -iv php < /vagrant/provisioning/httpd/httpd.conf > "${ALT_INSTALL_ROOT}/etc/httpd/conf/httpd.conf"
}

function install_php() {
  # Check the build php src dependencies
  find "${PHP_SRC_DIR}/libs" -iname "libphp?.so"
  if [[ $? != 0 ]]; then
    echo -n "There is no PHP library, continue to run make? [Y/n]: "
    read answer

    if [[ "$answer" =~ [Yy] ]]; then
      build_php_src
    else
      return 1
    fi
  fi

  local OLD_DIR=$(pwd)
  cd ${PHP_SRC_DIR}

  pre_install_php
  INSTALL_ROOT="${ALT_INSTALL_ROOT}" make install-cli install-sapi install-pharcmd
  post_install_php

  cd $OLD_DIR
}

function post_install_php() {
  rm -rf "${ALT_INSTALL_ROOT}/etc"
}

function build_rpm() {
  # Check the php make install dependencies
  find "${ALT_INSTALL_ROOT}" -iname "libphp?.so"
  if [[ $? != 0 ]]; then
    echo "Can not find PHP shared object from source: ${ALT_INSTALL_ROOT}!"
    echo -n "Will run make install, continue to run make install? [Y/n]: "
    read answer

    if [[ "$answer" =~ [Yy] ]]; then
      install_php
    else
      return 1
    fi
  fi

  clean_rpm

  fpm -s dir -t rpm \
  -n ${PHP_NAME} \
  -v ${PHP_VER} \
  -C "${ALT_INSTALL_ROOT}" \
  --license ${LICENSE} \
  --vendor ${VENDOR} \
  -p ${BUILD_DIR}
}

function install_rpm() {
  local package_path="${BUILD_DIR}/${PHP_NAME}-${PHP_VER}-1.x86_x64.rpm"
  rpm -iv ${package_path}
}

function clean_rpm() {
  rm -rf "${BUILD_DIR}/"*.rpm
}

function build_cmd() {
  case $1 in
    -php)
      echo "Building php from source!"
      build_php_src
      echo "Done"
      ;;
    -rpm)
      echo "Bulding rpm from PHP INSTALL_ROOT dir!"
      build_rpm
      echo "Done"
      ;;
    *)
      echo "Not supported build options: $1!"
  esac
}

function install_cmd() {
  case $1 in
    -php)
      echo "Installing PHP into target path!"
      install_php
      echo "Done"
      ;;
    -rpm)
      echo "Installing PHP rpm into system!"
      install_rpm
      echo "Done"
      ;;
    *)
      echo "Not supported install options: $1!"
  esac
}

function clean_cmd() {
  case $1 in
    -all)
      echo "Cleaning all the source!"
      ;;
    -rpm)
      echo "Cleaning rpm binary only!"
      ;;
    -install)
      echo "Cleaning installed php only!"
      ;;
    *)
      echo "Not supported options: $1!"
  esac
}

function cmd_help() {
  cat <<EOF
  ./build_php.bash -v={PHP_VERSION} sub_cmd [options]

  e.g:
  -v=5.3.29
  sub commands:
    build
      -php
      -rpm
    install
      -php
      -rpm
    clean
      -all
      -rpm
      -install
EOF
}

function options_parser() {
  if [[ "$1" =~ -v ]]; then
    PHP_VER=${1#-v=}
    PHP_SRC_DIR="${BUILD_DIR}/php-src-PHP-${PHP_VER}"

    shift

    if [[ ! "${PHP_VER}" =~ [0-9]\. ]]; then
      echo "Invalid PHP version: ${PHP_VER}!"
      return 1
    fi
  else
    echo "PHP version is missed! Please specify a valid version e.g: -v=5.3.29"
    echo
    return 1
  fi

  local sub_cmd=$1
  shift

  case $sub_cmd in
    build)
      build_cmd $*
      ;;
    install)
      install_cmd $*
      ;;
    clean)
      clean_cmd $*
      ;;
    *)
      echo "Missing supported sub command!"
      echo
      cmd_help
      ;;
  esac
}

function main() {
  options_parser $*
  #
  # init_setup
  # download_php_src
  # unzip_zipped_php
  # pre_make_install
  # build_php_src
  # fpm_build_rpm
  # cleanup
}

main $*
