# PHP-FPM 7.1 Docker

[![](https://images.microbadger.com/badges/version/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1") [![](https://images.microbadger.com/badges/image/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1") [![](https://images.microbadger.com/badges/license/cytopia/php-fpm-7.1.svg)](https://microbadger.com/images/cytopia/php-fpm-7.1 "php-fpm-7.1")

[![cytopia/php-fpm-7.1](http://dockeri.co/image/cytopia/php-fpm-7.1)](https://hub.docker.com/r/cytopia/php-fpm-7.1/)

----

PHP-FPM 7.1 Docker on CentOS 7


----

## Usage

```shell
$ docker run -i -t cytopia/php-fpm-7.1
```

## Options


### Environmental variables

#### Required environmental variables

- None

#### Optional environmental variables

| Variable | Type | Description |
|----------|------|-------------|
| DEBUG_COMPOSE_ENTRYPOINT | bool | Show shell commands executed during start.<br/>Value: `0` or `1` |
| TIMEZONE | string | Set docker OS timezone as well as PHP timezone.<br/>(Example: `Europe/Berlin`) |
| PHP_FPM_PORT | int | PHP-FPM listening Port |
| PHP_XDEBUG_ENABLE | bool | Enable Xdebug.<br/>Value: `0` or `1` |
| PHP_XDEBUG_REMOTE_PORT | int | The port on your Host (where you run the IDE/editor to which xdebug should connect.) |
| PHP_XDEBUG_REMOTE_HOST | string | The IP address of your Host (where you run the IDE/editor to which xdebug should connect). |
| PHP_MAX_EXECUTION_TIME | int | Corresponds to php.ini setting: `max_execution_time` |
| PHP_MAX_INPUT_TIME | int | Corresponds to php.ini setting: `max_input_time` |
| PHP_MEMORY_LIMIT | string | Corresponds to php.ini setting: `memory_limit` |
| PHP_POST_MAX_SIZE | string | Corresponds to php.ini setting: `post_max_size` |
| PHP_UPLOAD_MAX_FILESIZE | string | Corresponds to php.ini setting: `upload_max_filesize` |
| PHP_MAX_INPUT_VARS | int | Corresponds to php.ini setting: `max_input_vars` |
| PHP_ERROR_REPORTING | string | Corresponds to php.ini setting: `error_reporting` |
| PHP_DISPLAY_ERRORS | string | Corresponds to php.ini setting: `display_errors` |
| PHP_TRACK_ERRORS | string | Corresponds to php.ini setting: `track_errors` |
| FORWARD_MYSQL_PORT_TO_LOCALHOST | bool | Forward a remote MySQL server port to listen on this docker on `127.0.0.1`<br/>Value: `0` or `1` |
| MYSQL_REMOTE_ADDR | string | The remote IP address of the MySQL host from which to port-forward |
| MYSQL_REMOTE_PORT | int | The remote port of the MySQL host from which to port-forward |
| MYSQL_LOCAL_PORT | int | Forward the MySQL port to `127.0.0.1` to the specified local port |
| MOUNT_MYSQL_SOCKET_TO_LOCALDISK | bool | Mount a remote MySQL server socket to local disk on this docker.<br/>Value: `0` or `1` |
| MYSQL_SOCKET_PATH | string | Full socket path where the MySQL socket has been mounted on this docker. |

### Default mount points

| Docker | Description |
|--------|-------------|
| /var/log/php-fpm | PHP-FPM log dir |

### Default ports

| Docker | Description |
|--------|-------------|
| 9000   | PHP-FPM listening Port |
