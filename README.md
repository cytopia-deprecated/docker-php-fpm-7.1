# PHP-FPM 7.1 Docker

[![Build Status](https://travis-ci.org/cytopia/docker-php-fpm-7.1.svg?branch=master)](https://travis-ci.org/cytopia/docker-php-fpm-7.1) [![](https://images.microbadger.com/badges/version/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1") [![](https://images.microbadger.com/badges/image/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1") [![](https://images.microbadger.com/badges/license/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1")

[![cytopia/php-fpm-7.1](http://dockeri.co/image/cytopia/php-fpm-7.1)](https://hub.docker.com/r/cytopia/php-fpm-7.1/)

**[php-fpm 5.4](https://github.com/cytopia/docker-php-fpm-5.4) | [php-fpm 5.5](https://github.com/cytopia/docker-php-fpm-5.5) | [php-fpm 5.6](https://github.com/cytopia/docker-php-fpm-5.6) | [php-fpm 7.0](https://github.com/cytopia/docker-php-fpm-7.0) | php-fpm 7.1**

----

**PHP-FPM 7.1 Docker on CentOS 7**

[![Devilbox](https://raw.githubusercontent.com/cytopia/devilbox/master/.devilbox/www/htdocs/assets/img/devilbox_80.png)](https://github.com/cytopia/devilbox)

<sub>This docker image is part of the **[devilbox](https://github.com/cytopia/devilbox)**</sub>

----

## Options

### Environmental variables

#### Required environmental variables

- None

#### Optional environmental variables

| Variable | Type | Default |Description |
|----------|------|---------|------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | `0` | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | `UTC` | Set docker OS timezone as well as PHP timezone.<br/>(Example: `Europe/Berlin`) |
| ENABLE_MAIL | bool | `0` | Allow sending emails. Postfix will be configured for local delivery and all sent mails (even to real domains) will be catched locally. No email will ever go out. They will all be stored in a local `mailtrap` account.<br/>Value: `0` or `1` |
| FORWARD_MYSQL_PORT_TO_LOCALHOST | bool | `0` | Forward a remote MySQL server port to listen on this docker on `127.0.0.1`<br/>Value: `0` or `1` |
| MYSQL_REMOTE_ADDR | string | `` | The remote IP address of the MySQL host from which to port-forward.<br/>This is required if $FORWARD_MYSQL_PORT_TO_LOCALHOST is turned on. |
| MYSQL_REMOTE_PORT | int | `` | The remote port of the MySQL host from which to port-forward.<br/>This is required if $FORWARD_MYSQL_PORT_TO_LOCALHOST is turned on. |
| MYSQL_LOCAL_PORT | int | `` | Forward the MySQL port to `127.0.0.1` to the specified local port.<br/>This is required if $FORWARD_MYSQL_PORT_TO_LOCALHOST is turned on. |
| MOUNT_MYSQL_SOCKET_TO_LOCALDISK | bool | `0` | Mount a remote MySQL server socket to local disk on this docker.<br/>Value: `0` or `1` |
| MYSQL_SOCKET_PATH | string | `` | Full socket path where the MySQL socket has been mounted on this docker.<br/>This is recommended to adjust if $MOUNT_MYSQL_SOCKET_TO_LOCALDISK is turned on.<br/><br/>Example: `/tmp/mysql/mysqld.sock` |
| PHP_XDEBUG_ENABLE | bool | `0` | Enable Xdebug.<br/>Value: `0` or `1` |
| PHP_XDEBUG_REMOTE_PORT | int | `9000` | The port on your Host (where you run the IDE/editor to which xdebug should connect.) |
| PHP_XDEBUG_REMOTE_HOST | string | `` | The IP address of your Host (where you run the IDE/editor to which xdebug should connect).<br/>This is required if $PHP_DEBUG_ENABLE is turned on. |

### Default mount points

| Docker | Description |
|--------|-------------|
| /var/log/php-fpm | PHP-FPM log dir |
| /etc/php-custom.d | Custom user configuration files. Make sure to mount this folder to your host, where you have custom `*.ini` files. These files will then be copied to `/etc/php.d` during startup. |
| /var/mail | Mail mbox directory |

### Default ports

| Docker | Description |
|--------|-------------|
| 9000   | PHP-FPM listening Port |

## Usage

It is recommended to always use the `$TIMEZONE` variable which will set php's `date.timezone`.

**1. Provide FPM port to host**
```bash
$ docker run -i \
    -p 127.1.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -t cytopia/php-fpm-7.1
```

**2. Overwrite php.ini settings**

Mount a PHP config directory from your host into the PHP docker in order to overwrite php.ini settings.
```bash
$ docker run -i \
    -v ~/.etc/php.d:/etc/php-custom.d \
    -p 127.1.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -t cytopia/php-fpm-7.1
```


**3. MySQL connect via localhost (via socket mount)**

Mount a MySQL socket from `~/run/mysqld` (on your host) into the PHP docker.
By this, your PHP files inside the docker can use `localhost` to connect to a MySQL database.

Note that the `$MYSQL_SOCKET_PATH` (path to file) should match with the folder you mount into the docker.
```bash
$ docker run -i \
    -v ~/run/mysqld:/var/run/mysqld \
    -p 127.1.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -e MOUNT_MYSQL_SOCKET_TO_LOCALDISK=1 \
    -e MYSQL_SOCKET_PATH=/var/run/mysqld/mysqld.sock \
    -t cytopia/php-fpm-7.1
```

**4. MySQL connect via 127.1.0.1 (via port-forward)**

Forward MySQL Port from `172.168.0.30` (or any other IP address/hostname) and Port `3306` to the PHP docker on `127.1.0.1:3306`. By this, your PHP files inside the docker can use `127.1.0.1` to connect to a MySQL database.
```bash
$ docker run -i \
    -p 127.1.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -e FORWARD_MYSQL_PORT_TO_LOCALHOST=1 \
    -e MYSQL_REMOTE_ADDR=172.168.0.30 \
    -e MYSQL_REMOTE_PORT=3306 \
    -e MYSQL_LOCAL_PORT=3306 \
    -t cytopia/php-fpm-7.1
```

**5. Launch Postfix for mail-catching**

Once you `$ENABLE_MAIL=1`, all mails sent via any of your PHP applications no matter to which domain, are catched locally into the `mailtrap` account. You can also mount the mail directory locally to hook in with `mutt` and read those mails.
```bash
$ docker run -i \
    -p 127.0.0.1:9000:9000 \
	-v /tmp/mail:/var/mail \
    -e TIMEZONE=Europe/Berlin \
	-e ENABLE_MAIL=1 \
    -t cytopia/php-fpm-7.1
```

## Modules

**[Version]**

PHP 7.1.4 (cli) (built: Apr 11 2017 19:36:58) ( NTS )
Copyright (c) 1997-2017 The PHP Group
Zend Engine v3.1.0, Copyright (c) 1998-2017 Zend Technologies
    with Zend OPcache v7.1.4, Copyright (c) 1999-2017, by Zend Technologies

**[PHP Modules]**

apc, apcu, bcmath, bz2, calendar, Core, ctype, curl, date, dom, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imagick, imap, intl, json, ldap, libxml, mbstring, mcrypt, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, Phar, posix, pspell, readline, recode, redis, Reflection, session, shmop, SimpleXML, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, uploadprogress, wddx, xml, xmlreader, xmlrpc, xmlwriter, xsl, Zend OPcache, zlib

**[Zend Modules]**

Zend OPcache
