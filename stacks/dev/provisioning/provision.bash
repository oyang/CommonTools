#!/bin/bash
RUBY_VER=2.3.0

function config_yum() {
  echo "Config yum"
  sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm >/dev/null
  sudo rpm -Uvh http://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm >/dev/null

  for item in $(ls provisioning/yum) ; do
    sudo cp provisioning/yum/$item /etc/yum.repos.d
  done
  echo "Done"
}

function install_rpm() {
  echo "Installing built-in dependencies"
  local package_group='Development tools'
  local packages=()

  # Base utility
  packages+=("vim")
  packages+=("unzip")
  packages+=("bash-completion")
  packages+=("the_silver_searcher")

  # Devel dependencies for PHP
  packages+=("autoconf213")
  packages+=("libxml2-devel")
  packages+=("apr-devel")
  packages+=("openssl-devel")
  packages+=("libcurl-devel")
  packages+=("libmcrypt-devel")
  packages+=("gd-devel")
  packages+=("libc-client-devel")
  packages+=("openldap-devel")
  packages+=("httpd-devel")
  packages+=("xz-devel")
  packages+=("rpm-build")

  # Http server
  packages+=("httpd")

  # MySQL
  packages+=("mysql-community-server")
  packages+=("mysql-community-client")
  packages+=("mysql-community-devel")

  # RVM and Ruby dependencies
  pacakges+=("patch")
  pacakges+=("libyaml-devel")
  pacakges+=("glibc-headers")
  pacakges+=("glibc-devel")
  pacakges+=("readline-devel")
  pacakges+=("libffi-devel")
  pacakges+=("sqlite-devel")

  # Finally install all the packages
  sudo yum groupinstall "${package_group}" >/dev/null
  sudo yum install -y "${packages[@]}" >/dev/null
  echo "Done"
}

function link_autoconf() {
  echo "Linking autoconf213"

  if [ ! -L /usr/bin/autoconf ]; then
    sudo mv /usr/bin/autoconf /usr/bin/auto-conf.old
    sudo ln -s /usr/bin/autoconf-2.13 /usr/bin/autoconf
  fi
  if [ ! -L /usr/bin/autoheader ]; then
    sudo mv /usr/bin/autoheader /usr/bin/autoheader.old
    sudo ln -s /usr/bin/autoheader-2.13 /usr/bin/autoheader
  fi

  echo "Done"
}

function remove_welcome_conf() {
  echo "Removing /etc/httpd/conf.d/welcome.conf"
  local target_path='/etc/httpd/conf.d/welcome.conf'

  sudo rm -f ${target_path}
  echo "Done"
}

function install_rvm() {
  echo "Installing RVM to select right Ruby"

  # Download the GPG key first
  gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

  if ! rvm -v >/dev/null 2>&1 ; then
    curl -sSL https://get.rvm.io | bash -s stable --ruby >/dev/null
    source ~/.rvm/scripts/rvm
  else
    echo "RVM already existed!"
  fi

  # Select the default ruby
  rvm --default use ${RUBY_VER}
  ruby -v

  echo "Done"
}

function install_fpm() {
  echo "Install fpm for building portable package"
  gem install fpm >/dev/null
  echo "Done"
}

function config_httpd() {
  echo "Config httpd"
  for item in $(ls provisioning/httpd) ; do
    sudo cp provisioning/httpd/$item /etc/httpd/conf
  done
  echo "Done"
}

function reload_httpd() {
  echo "Restarting httpd service"
  sudo service httpd restart
  echo "Done"
}

function start_mysql_server() {
  echo "Starting mysqld service"
  sudo service mysqld start
  echo "Done"
}

function main() {
  cd /vagrant

  config_yum

  install_rpm
  link_autoconf

  install_rvm
  install_fpm

  remove_welcome_conf
  config_httpd
  reload_httpd
}

main
