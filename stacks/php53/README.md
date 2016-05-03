## Overview
This is a PHP building stack

## Setup
* Download php source from github(https://github.com/php/php-src) or other place.
* Unzip the download zip to a directory
* cd into the unzipped directory
* ./configure -{options}
* make -j3
* make install

## Build rpm package
* mkdir /tmp/php53
* mkdir /tmp/php53/etc/httpd/conf
* cp /etc/httpd/conf/httpd.conf /tmp/php53/etc/httpd/conf
* cd to php source folder
* INSTALL_ROOT=/tmp/php{version} make install
* rm -f /tmp/php53/etc/httpd/conf
* cd /tmp
* fpm -s dir -t rpm -n php -v 5.3.29 -C /tmp/php53 --license MIT
