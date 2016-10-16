#!/bin/sh -eu

###
### Variables
###
DEBUG_COMMANDS=0

# If $PHP_CUST_CONF_DIR is mounted from the
# host, all *.ini files from $PHP_CUST_CONF_DIR
# will be copied to $PHP_CONF_DIR
PHP_CONF_DIR="/etc/php.d"				# Default php config dir
PHP_CUST_CONF_DIR="/etc/php-custom.d"	# Custom php directory to look for *.ini files

PHP_XDEBUG_DEFAULT_PORT="9000"



###
### Functions
###
run() {
	_cmd="${1}"
	_debug="0"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"


	# If 2nd argument is set and enabled, allow debug command
	if [ "${#}" = "2" ]; then
		if [ "${2}" = "1" ]; then
			_debug="1"
		fi
	fi


	if [ "${DEBUG_COMMANDS}" = "1" ] || [ "${_debug}" = "1" ]; then
		printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	fi
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}

log() {
	_lvl="${1}"
	_msg="${2}"

	_clr_ok="\033[0;32m"
	_clr_info="\033[0;34m"
	_clr_warn="\033[0;33m"
	_clr_err="\033[0;31m"
	_clr_rst="\033[0m"

	if [ "${_lvl}" = "ok" ]; then
		printf "${_clr_ok}[OK]   %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "info" ]; then
		printf "${_clr_info}[INFO] %s${_clr_rst}\n" "${_msg}"
	elif [ "${_lvl}" = "warn" ]; then
		printf "${_clr_warn}[WARN] %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	elif [ "${_lvl}" = "err" ]; then
		printf "${_clr_err}[ERR]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	else
		printf "${_clr_err}[???]  %s${_clr_rst}\n" "${_msg}" 1>&2	# stdout -> stderr
	fi
}

# Test if argument is an integer.
#
# @param  mixed
# @return integer	0: is number | 1: not a number
isint(){
	printf "%d" "${1}" >/dev/null 2>&1 && return 0 || return 1;
}




################################################################################
# BOOTSTRAP
################################################################################

if set | grep '^DEBUG_COMPOSE_ENTRYPOINT='  >/dev/null 2>&1; then
	if [ "${DEBUG_COMPOSE_ENTRYPOINT}" = "1" ]; then
		DEBUG_COMMANDS=1
	fi
fi


################################################################################
# MAIN ENTRY POINT
################################################################################

###
### Adjust timezone
###

if ! set | grep '^TIMEZONE='  >/dev/null 2>&1; then
	log "warn" "\$TIMEZONE not set."
	log "warn" "Setting PHP: timezone=UTC"
	run "sed -i'' 's|;*date.timezone[[:space:]]*=.*$|date.timezone = UTC|g' /etc/php.ini"
else
	if [ -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
		# Unix Time
		log "info" "Setting docker timezone to: ${TIMEZONE}"
		run "rm /etc/localtime"
		run "ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime"

		# PHP Time
		log "info" "Setting PHP: timezone=${TIMEZONE}"
		run "sed -i'' 's|;*date.timezone[[:space:]]*=.*$|date.timezone = ${TIMEZONE}|g' /etc/php.ini"
	else
		log "err" "Invalid timezone for \$TIMEZONE."
		log "err" "\$TIMEZONE: '${TIMEZONE}' does not exist."
		exit 1
	fi
fi
log "info" "Docker date set to: $(date)"



###
### Custom PHP config
###

log "info" "Adding custom configuration files:"
run "find ${PHP_CUST_CONF_DIR} -type f -iname \"*.ini\" -exec echo \"Copying: {} to ${PHP_CONF_DIR}/\" \; -exec cp \"{}\" ${PHP_CONF_DIR}/ \;"



###
### PHP Xdebug
###

# Get xdebug config
XDEBUG_CONFIG="$( find /etc/php.d -name \*xdebug\*.ini )"


if ! set | grep '^PHP_XDEBUG_ENABLE=' >/dev/null 2>&1; then
	log "warn" "\$PHP_XDEBUG_ENABLE not set. Disable Xdebug"
	# Disable Xdebug
	if [ -f "${XDEBUG_CONFIG}" ]; then
		run "rm -f ${XDEBUG_CONFIG}"
	fi

else
	# ---- 1/3 Enabled ----
	if [ "${PHP_XDEBUG_ENABLE}" = "1" ]; then

		# 1.1 Check Xdebug Port
		if ! set | grep '^PHP_XDEBUG_REMOTE_PORT=' >/dev/null 2>&1; then
			log "warn" "\$PHP_XDEBUG_REMOTE_PORT not set, defaulting to ${PHP_XDEBUG_DEFAULT_PORT}"
			PHP_XDEBUG_REMOTE_PORT="${PHP_XDEBUG_DEFAULT_PORT}"

		elif ! isint "${PHP_XDEBUG_REMOTE_PORT}"; then
			log "warn" "\$PHP_XDEBUG_REMOTE_PORT is not a valid integer: ${PHP_XDEBUG_REMOTE_PORT}"
			log "warn" "\Defaulting to ${PHP_XDEBUG_DEFAULT_PORT}"
			PHP_XDEBUG_REMOTE_PORT="${PHP_XDEBUG_DEFAULT_PORT}"

		elif [ "${PHP_XDEBUG_REMOTE_PORT}" -lt "1" ] || [ "${PHP_XDEBUG_REMOTE_PORT}" -gt "65535" ]; then
			log "warn" "\$PHP_XDEBUG_REMOTE_PORT is out of range: ${PHP_XDEBUG_REMOTE_PORT}"
			log "warn" "\Defaulting to ${PHP_XDEBUG_DEFAULT_PORT}"
			PHP_XDEBUG_REMOTE_PORT="${PHP_XDEBUG_DEFAULT_PORT}"
		fi

		# 1.2 Check Xdebug remote Host (IP address of Docker Host [your computer])
		if ! set | grep '^PHP_XDEBUG_REMOTE_HOST=' >/dev/null 2>&1; then
			log "err" "\$PHP_XDEBUG_REMOTE_HOST not set, but required."
			log "err" "\$PHP_XDEBUG_REMOTE_HOST should be the IP of your Host with the IDE to which xdebug can connect."
			exit 1
		fi

		# 1.3 Check if Xdebug config exists
		if [ ! -f "${XDEBUG_CONFIG}" ]; then
			log "err" "No xdebug configuration file found."
			log "err" "This should not happen."
			log "err" "Please file a bug at https://github.com/cytopia/docker-php-fpm-7.1"
			exit 1
		fi

		# 1.4 Enable Xdebug
		log "info" "Setting PHP: xdebug.remote_enable=1"
		run "echo 'xdebug.remote_enable=1' >> ${XDEBUG_CONFIG}"

		log "info" "Setting PHP: xdebug.remote_connect_back=0"
		run "echo 'xdebug.remote_connect_back=0' >> ${XDEBUG_CONFIG}"

		log "info" "Setting PHP: xdebug.remote_port=${PHP_XDEBUG_REMOTE_PORT}"
		run "echo 'xdebug.remote_port=${PHP_XDEBUG_REMOTE_PORT}' >> ${XDEBUG_CONFIG}"

		log "info" "Setting PHP: xdebug.remote_host=${PHP_XDEBUG_REMOTE_HOST}"
		run "echo 'xdebug.remote_host=${PHP_XDEBUG_REMOTE_HOST}' >> ${XDEBUG_CONFIG}"

		log "info" "Setting PHP: xdebug.remote_log=\"/var/log/php-fpm/xdebug.log\""
		run "echo 'xdebug.remote_log=\"/var/log/php-fpm/xdebug.log\"' >> ${XDEBUG_CONFIG}"


	# ---- 2/3 Disabled ----
	elif [ "${PHP_XDEBUG_ENABLE}" = "0" ]; then
		log "info" "Disabling Xdebug"
		run "rm -f ${XDEBUG_CONFIG}"


	# ---- 3/3 Wrong value ----
	else
		log "err" "Invalid value for \$PHP_XDEBUG_ENABLE: ${PHP_XDEBUG_ENABLE}"
		log "err" "Must be '1' (for On) or '0' (for Off)"
		exit 1
	fi

fi



###
### Forward remote MySQL port to 127.0.0.1 ?
###
if ! set | grep '^FORWARD_MYSQL_PORT_TO_LOCALHOST=' >/dev/null 2>&1; then
	log "warn" "\$FORWARD_MYSQL_PORT_TO_LOCALHOST not set."
	log "warn" "Not forwading MySQL port to 127.0.0.1 inside docker"
else

	if [ "${FORWARD_MYSQL_PORT_TO_LOCALHOST}" = "1" ]; then
		if ! set | grep '^MYSQL_REMOTE_ADDR=' >/dev/null 2>&1; then
			log "err" "You have enabled to port-forward database port to 127.0.0.1."
			log "err" "\$MYSQL_REMOTE_ADDR must be set for this to work."
			exit 1
		fi
		if ! set | grep '^MYSQL_REMOTE_PORT=' >/dev/null 2>&1; then
			log "err" "You have enabled to port-forward database port to 127.0.0.1."
			log "err" "\$MYSQL_REMOTE_PORT must be set for this to work."
			exit 1
		fi
		if ! set | grep '^MYSQL_LOCAL_PORT=' >/dev/null 2>&1; then
			log "err" "You have enabled to port-forward database port to 127.0.0.1."
			log "err" "\$MYSQL_LOCAL_PORT must be set for this to work."
			exit 1
		fi

		##
		## Start socat tunnel
		## bring mysql to localhost
		##
		## This allos to connect via mysql -h 127.0.0.1
		##
		log "info" "Forwarding $MYSQL_REMOTE_ADDR:$MYSQL_REMOTE_PORT to 127.0.0.1:${MYSQL_LOCAL_PORT} inside this docker."
		run "/usr/bin/socat tcp-listen:${MYSQL_LOCAL_PORT},reuseaddr,fork tcp:$MYSQL_REMOTE_ADDR:$MYSQL_REMOTE_PORT &"

	elif [ "${FORWARD_MYSQL_PORT_TO_LOCALHOST}" = "0" ]; then
		log "info" "Not forwading MySQL port to 127.0.0.1 inside docker"

	else
		log "err" "Invalid value for \$FORWARD_MYSQL_PORT_TO_LOCALHOST"
		log "err" "Only 1 (for on) or 0 (for off) are allowed"
		exit 1
	fi
fi



###
### Mount remote MySQL socket volume to local disk?
###
if ! set | grep '^MOUNT_MYSQL_SOCKET_TO_LOCALDISK=' >/dev/null 2>&1; then
	log "warn" "\$MOUNT_MYSQL_SOCKET_TO_LOCALDISK not set."
	log "warn" "Not mounting MySQL socket inside docker."
else
	if [ "${MOUNT_MYSQL_SOCKET_TO_LOCALDISK}" = "1" ]; then
		if ! set | grep '^MYSQL_SOCKET_PATH=' >/dev/null 2>&1; then
			log "err" "You have enabled to mount mysql socket to local disk."
			log "err" "\$MYSQL_SOCKET_PATH must be set for this to work."
			exit 1
		fi

		##
		## Tell MySQL Client where the socket can be found.
		##
		## This allos to connect via mysql -h localhost
		##
		log "info" "Setting MySQL client config: socket=${MYSQL_SOCKET_PATH}"

		run "echo '[client]'						> /etc/my.cnf"
		run "echo 'socket = ${MYSQL_SOCKET_PATH}'	>> /etc/my.cnf"

		run "echo '[mysql]'							>> /etc/my.cnf"
		run "echo 'socket = ${MYSQL_SOCKET_PATH}'	>> /etc/my.cnf"



		##
		## Tell PHP where the socket can be found.
		##
		## This allos to connect via mysql -h localhost
		##
		log "info" "Setting PHP: mysql.default_socket=${MYSQL_SOCKET_PATH}"
		run "sed -i'' 's|mysql.default_socket.*$|mysql.default_socket = ${MYSQL_SOCKET_PATH}|g' /etc/php.ini"

		log "info" "Setting PHP: mysqli.default_socket=${MYSQL_SOCKET_PATH}"
		run "sed -i'' 's|mysqli.default_socket.*$|mysqli.default_socket = ${MYSQL_SOCKET_PATH}|g' /etc/php.ini"

		log "info" "Setting PHP: pdo_mysql.default_socket=${MYSQL_SOCKET_PATH}"
		run "sed -i'' 's|pdo_mysql.default_socket.*$|pdo_mysql.default_socket = ${MYSQL_SOCKET_PATH}|g' /etc/php.ini"

	elif [ "${MOUNT_MYSQL_SOCKET_TO_LOCALDISK}" = "0" ]; then
		log "info" "Not mounting MySQL socket inside docker."

	else
		log "err" "Invalid value for \$MOUNT_MYSQL_SOCKET_TO_LOCALDISK"
		log "err" "Only 1 (for on) or 0 (for off) are allowed"
		exit 1
	fi
fi



###
### Start
###
log "info" "Starting $(php-fpm -v 2>&1 | head -1)"
run "/usr/sbin/php-fpm -F" "1"
