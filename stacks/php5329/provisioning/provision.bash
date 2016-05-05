#!/bin/bash
function install_builtin_rpm() {
  echo "Installing built-in dependencies"
  packages[0]="vim"
  packages[1]="unzip"
  packages[2]="httpd"
  packages[3]="libc-client-devel"
  packages[4]="libpng"
  packages[5]="git-all"

  sudo yum install -y "${packages[@]}" >/dev/null
  echo "Done"
}

function install_epel() {
  echo "Installing EPEL for more packages"
  rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm >/dev/null
  rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm >/dev/null
  echo "Done"
}

function install_mysql55() {
  echo "Installing MySQL55 server and client"
  yum remove -y mysql mysql-server mysql-libs >/dev/null
  yum install -y mysql55w mysql55w-server >/dev/null
  echo "Done"
}

function install_customized_php() {
  echo "Installing customized PHP"
  local src_path="https://googledrive.com/host/0B3GvHk47TiJAeEp1cm1VSWgtRWs/php-5.3.29-1.x86_64.rpm"
  local target_path="/tmp/php5.3.29.rpm"
  rm -rf "${target_path}"

  wget -O ${target_path} ${src_path} >/dev/null 2>&1

  sudo rpm -i ${target_path}
  rm -rf "${target_path}"
  echo "Done"
}

function copy_httpd_conf() {
  echo "Applying httpd.conf"
  local src_path="provisioning/httpd/httpd.conf"
  local target_path="/etc/httpd/conf/httpd.conf"

  sudo cp ${src_path} ${target_path}
  echo "Done"
}

function copy_php_ini() {
  echo "Applying php.ini"
  local src_path="provisioning/php/php.ini"
  local target_path="/usr/local/lib/php.ini"

  sudo cp ${src_path} ${target_path}
  echo "Done"
}

function copy_phpinfo() {
  echo "Copying phpinfo.php"
  local src_path="provisioning/test/phpinfo.php"
  local target_path="/var/www/html/phpinfo.php"

  sudo cp ${src_path} ${target_path}
  echo "Done"
}

function remove_welcome_conf() {
  echo "Removing /etc/httpd/conf.d/welcome.conf"
  local target_path="/etc/httpd/conf.d/welcome.conf"

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

function install_phpmyadmin() {
  echo "Installing phpMyAdmin"
  local phpmyadmin_source_link="https://files.phpmyadmin.net/phpMyAdmin/4.0.10.15/phpMyAdmin-4.0.10.15-all-languages.tar.gz"
  local phpmyadmin_extract_name="phpMyAdmin-4.0.10.15-all-languages"
  local phpmyadmin_zip="/tmp/phpmyadmin.tgz"
  local phpmyadmin_extract_name="phpMyAdmin-4.0.10.15-all-languages"
  local phpmyadmin_config="provisioning/phpmyadmin/config.inc.php"
  local phpmyadmin_target="/var/www/html/phpmyadmin"

  rm -rf "${phpmyadmin_zip}"
  sudo rm -rf "${phpmyadmin_target}"
  wget -O ${phpmyadmin_zip} ${phpmyadmin_source_link} >/dev/null
  sudo tar xzf ${phpmyadmin_zip} -C /tmp
  sudo mv "/tmp/${phpmyadmin_extract_name}" "${phpmyadmin_target}"
  sudo cp ${phpmyadmin_config} ${phpmyadmin_target}

  echo "Done"
}

function main() {
  cd /vagrant

  install_builtin_rpm
  install_epel
  install_mysql55
  install_customized_php
  copy_httpd_conf
  copy_php_ini
  copy_phpinfo
  remove_welcome_conf
  reload_httpd
  start_mysql_server
  install_phpmyadmin
}

main
