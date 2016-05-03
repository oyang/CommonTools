#!/bin/bash
function install_builtin_rpm() {
  echo "Installing built-in dependencies"
  package_group='Development tools'

  packages[0]='vim'
  packages[1]='unzip'
  packages[2]='autoconf213'
  packages[3]='libxml2-devel'
  packages[4]='apr-devel'
  packages[5]='openssl-devel'
  packages[6]='libcurl-devel'
  packages[7]='gd-devel'
  packages[8]='libc-client-devel'
  packages[9]='openldap-devel'
  packages[10]='httpd-devel'
  packages[11]='mysql-devel'
  packages[12]='httpd'
  packages[13]='mysql-server'
  packages[14]='xz-devel'

  sudo yum groupinstall "${package_group}"
  sudo yum install -y "${packages[@]}"
  echo "Done"
}

function link_autoconf() {
  sudo ln -s /usr/bin/autoconf-2.13 /usr/bin/autoconf
  sudo ln -s /usr/bin/autoheader-2.13 /usr/bin/autoheader
}

function remove_welcome_conf() {
  echo "Removing /etc/httpd/conf.d/welcome.conf"
  local target_path='/etc/httpd/conf.d/welcome.conf'

  sudo rm -f ${target_path}
  echo "Done"
}

function install_rvm() {
  echo "Installing RVM to select right Ruby"
  if ! rvm -v >/dev/null 2>&1 ; then
    curl -sSL https://get.rvm.io | bash -s stable --ruby
    source ~/.rvm/scripts/rvm
  else
    echo "RVM already existed!"
  fi
  ruby -v
  echo "Done"
}

function install_fpm() {
  echo "Install fpm for building portable package"
  gem install fpm
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

  install_builtin_rpm
  link_autoconf

  install_rvm
  install_fpm

  remove_welcome_conf
  reload_httpd
  start_mysql_server
}

main
