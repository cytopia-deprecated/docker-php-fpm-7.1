# PHP-FPM 7.1 Docker

<small>**Latest build:** 2017-08-09</small>

[![Build Status](https://travis-ci.org/cytopia/docker-php-fpm-7.1.svg?branch=master)](https://travis-ci.org/cytopia/docker-php-fpm-7.1) [![](https://images.microbadger.com/badges/version/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1") [![](https://images.microbadger.com/badges/image/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1") [![](https://images.microbadger.com/badges/license/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1")

[![cytopia/php-fpm-7.1](http://dockeri.co/image/cytopia/php-fpm-7.1)](https://hub.docker.com/r/cytopia/php-fpm-7.1/)

**[php-fpm 5.4](https://github.com/cytopia/docker-php-fpm-5.4) | [php-fpm 5.5](https://github.com/cytopia/docker-php-fpm-5.5) | [php-fpm 5.6](https://github.com/cytopia/docker-php-fpm-5.6) | [php-fpm 7.0](https://github.com/cytopia/docker-php-fpm-7.0) | php-fpm 7.1 | [php-fpm 7.2](https://github.com/cytopia/docker-php-fpm-7.2) | [HHVM latest](https://github.com/cytopia/docker-hhvm-latest)**

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
| DOCKER_LOGS_ERROR | bool | `0` | Log errors to `docker logs` instead of file inside container.<br/>Value: `0` or `1`<br/>**Note:** When using this container with a webserver and set to `1` (log to `docker logs`), php errors will strangely be redirected to the webservers error log. So also make sure to send the webserver error log to `docker logs`.|
| DOCKER_LOGS_ACCESS | bool | `0` | Log access to `docker logs` instead of file inside container.<br/>Value: `0` or `1` |
| DOCKER_LOGS_XDEBUG | bool | `0` | Log php xdebug to `docker logs` instead of file inside container.<br/>Value: `0` or `1` |
| NEW_UID | integer | `1000` | Assign the default `devilbox` user a new UID. This is useful if you also want to work inside this container in order to be able to access your mounted files with the same UID. Set it to your host users uid (see `id` for your uid). |
| NEW_GID | integer | `1000` | Assign the default `devilbox` group a new GID. This is useful if you also want to work inside this container in order to be able to access your mounted files with the same GID. Set it to your host group gid (see `id` for your gid). |
| TIMEZONE | string | `UTC` | Set docker OS timezone as well as PHP timezone.<br/>(Example: `Europe/Berlin`) |
| ENABLE_MAIL | bool | `0` | Allow sending emails. Postfix will be configured for local delivery and all sent mails (even to real domains) will be catched locally. No email will ever go out. They will all be stored in a local `devilbox` account.<br/>Value: `0` or `1` |
| FORWARD_PORTS_TO_LOCALHOST | string | `` | List of remote ports to forward to `127.0.0.1`.<br/>Format: `<local-port>:<remote-host>:<remote-port>`. You can separate multiple entries by comma.<br/>Example: `3306:mysqlhost:3306, 6379:192.0.1.1:6379` |
| PHP_XDEBUG_ENABLE | bool | `0` | Enable Xdebug.<br/>Value: `0` or `1` |
| PHP_XDEBUG_REMOTE_PORT | int | `9000` | The port on your Host (where you run the IDE/editor to which xdebug should connect.) |
| PHP_XDEBUG_REMOTE_HOST | string | `` | The IP address of your Host (where you run the IDE/editor to which xdebug should connect).<br/>This is required if $PHP_DEBUG_ENABLE is turned on. |
| MYSQL_BACKUP_USER | string | mds default | Username for mysql backups used for bundled [mysqldump-secure](https://mysqldump-secure.org) |
| MYSQL_BACKUP_PASS | string | mds default | Password for mysql backups used for bundled [mysqldump-secure](https://mysqldump-secure.org) |
| MYSQL_BACKUP_HOST | string | mds default | Hostname for mysql backups used for bundled [mysqldump-secure](https://mysqldump-secure.org) |

### Default mount points

| Docker | Description |
|--------|-------------|
| /var/log/php | PHP-FPM log dir |
| /etc/php-custom.d | Custom user configuration files. Make sure to mount this folder to your host, where you have custom `*.ini` files. These files will then be copied to `/etc/php.d` during startup. |
| /var/mail | Mail mbox directory |

### Default ports

| Docker | Description |
|--------|-------------|
| 9000   | PHP-FPM listening Port |

## Usage

It is recommended to always use the `$TIMEZONE` variable which will set php's `date.timezone`.

**1. Provide FPM port to host**
```shell
$ docker run -i \
    -p 127.0.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -t cytopia/php-fpm-7.1
```

**2. Overwrite php.ini settings**

Mount a PHP config directory from your host into the PHP docker in order to overwrite php.ini settings.
```shell
$ docker run -i \
    -v ~/.etc/php.d:/etc/php-custom.d \
    -p 127.0.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -t cytopia/php-fpm-7.1
```


**3. MySQL connect via 127.0.0.1 (via port-forward)**

Forward MySQL Port from `172.168.0.30` (or any other IP address/hostname) and Port `3306` to the PHP docker on `127.0.0.1:3306`. By this, your PHP files inside the docker can use `127.0.0.1` to connect to a MySQL database.
```shell
$ docker run -i \
    -p 127.0.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -e FORWARD_PORTS_TO_LOCALHOST='3306:172.168.0.30:3306' \
    -t cytopia/php-fpm-7.1
```

**4. MySQL and Redis connect via 127.0.0.1 (via port-forward)**

Forward MySQL Port from `172.168.0.30:3306` and Redis port from `redis:6379` to the PHP docker on `127.0.0.1:3306` and `127.0.0.1:6379`. By this, your PHP files inside the docker can use `127.0.0.1` to connect to a MySQL or Redis database.
```shell
$ docker run -i \
    -p 127.0.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -e FORWARD_PORTS_TO_LOCALHOST='3306:172.168.0.30:3306, 6379:redis:6379' \
    -t cytopia/php-fpm-7.1
```

**5. MySQL connect via localhost (via socket mount)**

Mount a MySQL socket from `~/run/mysqld/mysqld.sock` (on your host) into the PHP docker to `/tmp/mysql/mysqld.sock`.
By this, your PHP files inside the docker can use `localhost` to connect to a MySQL database.
In order to make php aware of new path of the mysql socket, we will also have to create a php config file and mount it into the container.

```shell
# Show local custom php config
$ cat ~/tmp/cfg/php/my-config.ini
mysql.default_socket = /tmp/mysql/mysqld.sock
mysqli.default_socket = /tmp/mysql/mysqld.sock
pdo_mysql.default_socket = /tmp/mysql/mysqld.sock

# Start container with mounted socket and config
$ docker run -i \
    -v ~/run/mysqld:/tmp/mysql \
    -v ~/tmp/cfg/php:/etc/php-custom.d \
    -p 127.0.0.1:9000:9000 \
    -e TIMEZONE=Europe/Berlin \
    -t cytopia/php-fpm-7.1
```


**6. Launch Postfix for mail-catching**

Once you `$ENABLE_MAIL=1`, all mails sent via any of your PHP applications no matter to which domain, are catched locally into the `devilbox` account. You can also mount the mail directory locally to hook in with `mutt` and read those mails.
```shell
$ docker run -i \
    -p 127.0.0.1:9000:9000 \
    -v /tmp/mail:/var/mail \
    -e TIMEZONE=Europe/Berlin \
    -e ENABLE_MAIL=1 \
    -t cytopia/php-fpm-7.1
```

**7. Run with webserver that supports PHP-FPM**

`~/my-host-www` will be the directory that serves the php files (your document root).
Make sure to mount it into both, php and the webserver.

```shell
# Start myself
$ docker run -d \
    -p 9000 \
    -v ~/my-host-www:/var/www/html \
    --name php \
    -t cytopia/php-fpm-7.1

# Start webserver and link into myself
$ docker run -d \
    -p 80:80 \
    -v ~/my-host-www:/var/www/html \
    -e PHP_FPM_ENABLE=1 \
    -e PHP_FPM_SERVER_ADDR=php \
    -e PHP_FPM_SERVER_PORT=9000 \
    --link php \
    -t cytopia/nginx-mainline
```

## Modules

**[Version]**

PHP 7.1.8 (cli) (built: Aug  2 2017 12:13:05) ( NTS )
Copyright (c) 1997-2017 The PHP Group
Zend Engine v3.1.0, Copyright (c) 1998-2017 Zend Technologies
    with Zend OPcache v7.1.8, Copyright (c) 1999-2017, by Zend Technologies
    with Xdebug v2.5.5, Copyright (c) 2002-2017, by Derick Rethans

**[PHP Modules]**

apc, apcu, bcmath, bz2, calendar, Core, ctype, curl, date, dom, exif, fileinfo, filter, ftp, gd, gettext, gmp, hash, iconv, igbinary, imagick, imap, intl, json, ldap, libxml, mbstring, mcrypt, memcache, memcached, mongodb, msgpack, mysqli, mysqlnd, openssl, pcntl, pcre, PDO, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, phalcon, Phar, posix, pspell, readline, recode, redis, Reflection, session, shmop, SimpleXML, soap, sockets, SPL, sqlite3, standard, sysvmsg, sysvsem, sysvshm, tidy, tokenizer, uploadprogress, wddx, xdebug, xml, xmlreader, xmlrpc, xmlwriter, xsl, Zend OPcache, zip, zlib

**[Zend Modules]**

Xdebug, Zend OPcache

**[Tools]**

| tool           | version |
|----------------|---------|
| [composer](https://getcomposer.org)    | 1.5.0 |
| [drupal-console](https://drupalconsole.com) | 1.0.0 |
| [drush](http://www.drush.org)          | 8.1.12 |
| [git](https://git-scm.com)             | 1.8.3.1 |
| [laravel installer](https://github.com/laravel/installer)     | 1.3.7 |
| [mysqldump-secure](https://mysqldump-secure.org) | 0.16.3 |
| [node](https://nodejs.org)             | 6.11.1 |
| [npm](https://www.npmjs.com)           | 3.10.10 |
| [phalcon-devtools](https://github.com/phalcon/phalcon-devtools)   | 3.0.5 |
| [symfony installer](https://github.com/symfony/symfony-installer) | 1.5.9 |
| [wp-cli](https://wp-cli.org)           | 1.3.0 |

**[Misc Tools]**

mongodump, mongoexport, mongofiles, mongoimport, mongooplog, mongoperf, mongorestore, mongostat, mongotop, msql2mysql, mysql, mysqlaccess, mysqladmin, mysqlbinlog, mysqlcheck, mysqldump, mysql_find_rows, mysqlimport, mysqlshow, mysqlslap, mysql_waitpid, pg_basebackup, pg_dump, pg_dumpall, pg_restore, psql
