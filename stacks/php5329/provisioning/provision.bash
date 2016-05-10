#!/bin/bash
DOCUMENT_ROOT='/var/www'
MYSQL_PASSWORD='test'

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

  local packages=()
  packages+=("expect")
  packages+=("vim")
  packages+=("unzip")
  packages+=("httpd")
  packages+=("libc-client-devel")
  packages+=("libpng")
  packages+=("git-all")
  packages+=("centos-release")
  packages+=("libmcrypt-devel")

  yum install -y "${packages[@]}" >/dev/null
  echo "Done"
}

function install_epel() {
  echo "Installing EPEL for more packages"
  remove_packages epel-release webtatic-release
  rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm >/dev/null
  rpm -Uvh http://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm >/dev/null
  echo "Done"
}

function config_yum() {
  echo "Configing yum repo"
  local target_path="/etc/yum.repos.d/"
  for item in $(ls provisioning/yum) ; do
    cp "provisioning/yum/$item" ${target_path}
  done
  echo "Done"
}

function install_mysql55() {
  echo "Installing MySQL55 server and client"
  local to_remove=()
  to_remove+=("mysql")
  to_remove+=("mysql-server")
  to_remove+=("mysql-libs")

  remove_packages ${to_remove[@]}
  yum install -y mysql-community-client mysql-community-server >/dev/null
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

  if [ -f ${target_path} ];then
    mv ${target_path} "${target_path}.bak"
  fi

  cp ${src_path} ${target_path}
  echo "Done"
}

function copy_php_ini() {
  echo "Applying php.ini"
  local src_path="provisioning/php/php.ini"
  local target_path="/usr/local/lib/php.ini"

  if [ -f ${target_path} ]; then
    mv ${target_path} "${target_path}.bak"
  fi

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

function mysql_secure_install() {
  local current_passwd=""

  if mysql -uroot -p"${MYSQL_PASSWORD}" -e "select now();" 2>&1 >/dev/null ; then
    echo "Ignored! Won't run mysql_secure_installation twice!"
    return 0
  fi

  if ! mysql -uroot -e "select now();" 2>&1 >/dev/null ; then
    echo "You updated the default MySQL password, can not run mysql_secure_installation!"
    return 1
  fi

  echo "Running /usr/bin/mysql_secure_installation"
  expect <<EOD
  log_user 0
  spawn /usr/bin/mysql_secure_installation
  expect "Enter current password for root"
  send "${current_passwd}\r"
  expect "Change the root password"
  send "Y\r"
  expect "New password"
  send "${MYSQL_PASSWORD}\r"
  expect "Re-enter new password"
  send "${MYSQL_PASSWORD}\r"
  expect "Remove anonymous users"
  send "Y\r"
  expect "Disallow root login remotely"
  send "n\r"
  expect "Remove test database and access to it"
  send "Y\r"
  expect "Reload privilege tables now"
  send "Y\r"
EOD
  echo "Done."
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
  config_yum
  install_mysql55
  install_customized_php
  copy_httpd_conf
  copy_php_ini
  copy_phpinfo
  remove_welcome_conf
  reload_httpd
  start_mysql_server
  mysql_secure_install
  install_phpmyadmin
}

main
