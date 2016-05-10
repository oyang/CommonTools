#!/bin/bash
PHP_NAME="php"
PHP_VER="5.3.29"
LICENSE="PHP"
VENDOR="oyang"
BUILD_DIR="/tmp/build_php"
ALT_INSTALL_ROOT="${BUILD_DIR}/INSTALL_ROOT"

function init_setup() {
  mkdir -p "${ALT_INSTALL_ROOT}"
}

function download_php_src() {
  wget -c -O "${BUILD_DIR}/PHP-${PHP_VER}.zip" "https://github.com/php/php-src/archive/PHP-${PHP_VER}.zip"
}

function unzip_zipped_php() {
  unzip -d "${BUILD_DIR}" "${BUILD_DIR}/PHP-${PHP_VER}.zip"
}

function build_php_src() {
  local OLD_DIR=$(pwd)
  cd "${BUILD_DIR}/php-src-PHP-${PHP_VER}"

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

  pre_make_install
  INSTALL_ROOT="${ALT_INSTALL_ROOT}" make install-cli install-sapi install-pharcmd
  post_make_install

  cd ${OLD_DIR}
}

function pre_make_install() {
  mkdir -p "${ALT_INSTALL_ROOT}/etc/httpd/conf"
  grep -iv php < /vagrant/provisioning/httpd/httpd.conf > "${ALT_INSTALL_ROOT}/etc/httpd/conf/httpd.conf"
}

function post_make_install() {
  rm -rf "${ALT_INSTALL_ROOT}/etc"
}

function fpm_build_rpm() {
  fpm -s dir -t rpm \
  -n ${PHP_NAME} \
  -v ${PHP_VER} \
  -C "${ALT_INSTALL_ROOT}" \
  --license ${LICENSE} \
  --vendor ${VENDOR}
}

function cleanup() {
  rm -rf "${BUILD_DIR}/*.rpm"
}

function main() {
  if [ -n $1 ]; then
    PHP_VER="$1"
    echo "Will build php: ${PHP_VER}"
  fi

  init_setup
  download_php_src
  unzip_zipped_php
  pre_make_install
  build_php_src
  fpm_build_rpm
  cleanup
}

main $*
