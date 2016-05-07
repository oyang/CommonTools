#!/bin/bash
DOCUMENT_ROOT='/var/www'

function remove_packages() {
  while [ -n "$1" ]; do
    if yum -q list installed $1 >/dev/null 2>&1; then
      yum -q remove -y $1 >/dev/null
    fi
    shift
  done
}

function install_builtin_rpm() {
  echo "Installing built-in dependencies"
  # Import PGP key first
  rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6

  packages[0]="vim"
  packages[1]="unzip"
  packages[2]="httpd"
  packages[3]="libc-client-devel"
  packages[4]="libpng"
  packages[5]="git-all"
  packages[6]='centos-release'

  yum install -y "${packages[@]}" >/dev/null
  echo "Done"
}

function install_epel() {
  echo "Installing EPEL for more packages"
  remove_packages epel-release webtatic-release
  rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm >/dev/null
  rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm >/dev/null
  echo "Done"
}

function install_mysql55() {
  echo "Installing MySQL55 server and client"
  local to_remove=(mysql mysql-server mysql-libs)
  remove_packages ${to_remove[@]}
  yum install -y mysql55w mysql55w-server >/dev/null
  echo "Done"
}

function install_customized_php() {
  echo "Installing customized PHP"
  local src_path="https://googledrive.com/host/0B3GvHk47TiJAeEp1cm1VSWgtRWs/php-5.3.29-1.x86_64.rpm"
  local target_path="/tmp/php5.3.29.rpm"

  remove_packages php
  rm -rf "${target_path}"

  wget -q -O ${target_path} ${src_path}

  rpm -i ${target_path}
  rm -rf "${target_path}"
  echo "Done"
}

function copy_httpd_conf() {
  echo "Applying httpd.conf"
  local src_path="provisioning/httpd/httpd.conf"
  local target_path="/etc/httpd/conf/httpd.conf"

  cp ${src_path} ${target_path}
  echo "Done"
}

function copy_php_ini() {
  echo "Applying php.ini"
  local src_path="provisioning/php/php.ini"
  local target_path="/usr/local/lib/php.ini"

  cp ${src_path} ${target_path}
  echo "Done"
}

function copy_phpinfo() {
  echo "Copying phpinfo.php"
  local src_path="provisioning/test/phpinfo.php"
  local target_path="${DOCUMENT_ROOT}/html/phpinfo.php"

  cp ${src_path} ${target_path}
  echo "Done"
}

function remove_welcome_conf() {
  echo "Removing /etc/httpd/conf.d/welcome.conf"
  local target_path="/etc/httpd/conf.d/welcome.conf"

  rm -f ${target_path}
  echo "Done"
}

function reload_httpd() {
  echo "Restarting httpd service"
  service httpd restart
  echo "Done"
}

function start_mysql_server() {
  echo "Starting mysqld service"
  service mysqld start
  echo "Done"
}

function install_phpmyadmin() {
  echo "Installing phpMyAdmin"
  local phpmyadmin_source_link="https://files.phpmyadmin.net/phpMyAdmin/4.0.10.15/phpMyAdmin-4.0.10.15-all-languages.tar.gz"
  local phpmyadmin_extract_name="phpMyAdmin-4.0.10.15-all-languages"
  local phpmyadmin_zip="/tmp/phpmyadmin.tgz"
  local phpmyadmin_extract_name="phpMyAdmin-4.0.10.15-all-languages"
  local phpmyadmin_config="provisioning/phpmyadmin/config.inc.php"
  local phpmyadmin_target="${DOCUMENT_ROOT}/html/phpmyadmin"

  rm -rf "${phpmyadmin_zip}"
  rm -rf "${phpmyadmin_target}"
  wget -q -O ${phpmyadmin_zip} ${phpmyadmin_source_link} >/dev/null
  tar xzf ${phpmyadmin_zip} -C /tmp
  mv "/tmp/${phpmyadmin_extract_name}" "${phpmyadmin_target}"
  cp ${phpmyadmin_config} ${phpmyadmin_target}

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
