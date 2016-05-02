#!/bin/bash
function install_builtin_rpm() {
  echo "Installing built-in dependencies"
  packages[0]='vim'
  packages[1]='unzip'
  packages[2]='httpd'
  packages[3]='mysql-server'
  packages[4]='libc-client-devel'
  packages[5]='libpng'

  sudo yum install -y "${packages[@]}"
  echo "Done"
}

function install_customized_php() {
  echo "Installing customized PHP"
  local src_path='https://googledrive.com/host/0B3GvHk47TiJAeEp1cm1VSWgtRWs/php53-1.0-1.x86_64.rpm'
  local target_path='/tmp/php5.3.29.rpm'

  wget -O ${target_path} ${src_path} >/dev/null 2>&1

  sudo rpm -i ${target_path}
  echo "Done"
}

function copy_httpd_conf() {
  echo "Applying httpd.conf"
  local src_path='provisioning/httpd/httpd.conf'
  local target_path='/etc/httpd/conf/httpd.conf'

  sudo cp ${src_path} ${target_path}
  echo "Done"
}

function copy_php_ini() {
  echo "Applying php.ini"
  local src_path='provisioning/php/php.ini'
  local target_path='/usr/local/lib/php.ini'

  sudo cp ${src_path} ${target_path}
  echo "Done"
}

function copy_phpinfo() {
  echo "Copying phpinfo.php"
  local src_path='provisioning/test/phpinfo.php'
  local target_path='/var/www/html/phpinfo.php'

  sudo cp ${src_path} ${target_path}
  echo "Done"
}

function remove_welcome_conf() {
  echo "Removing /etc/httpd/conf.d/welcome.conf"
  local target_path='/etc/httpd/conf.d/welcome.conf'

  sudo rm -f ${target_path}
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
  install_customized_php
  copy_httpd_conf
  copy_php_ini
  copy_phpinfo
  remove_welcome_conf
  reload_httpd
  start_mysql_server
}

main
