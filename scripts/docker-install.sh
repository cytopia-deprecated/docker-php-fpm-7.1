#!/bin/sh -eu

###
### Variables
###
PHP_FPM_POOL_CONF="/etc/php-fpm.d/www.conf"
PHP_FPM_CONF="/etc/php-fpm.conf"


###
### Functions
###
print_headline() {
	_txt="${1}"
	_blue="\033[0;34m"
	_reset="\033[0m"

	printf "${_blue}\n%s\n${_reset}" "--------------------------------------------------------------------------------"
	printf "${_blue}- %s\n${_reset}" "${_txt}"
	printf "${_blue}%s\n\n${_reset}" "--------------------------------------------------------------------------------"
}

run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}$( echo "${_cmd}" | sed 's|%|%%|g' )${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


################################################################################
# MAIN ENTRY POINT
################################################################################


###
### Configure php.ini
###
print_headline "5. Configure php.ini"

# Fix fix_pathinfo (security precaution for php-fpm)
run "sed -i'' 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo = 0/g' /etc/php.ini"
grep -q '^cgi.fix_pathinfo = 0$' /etc/php.ini
if [ "$( grep -c '^cgi.fix_pathinfo[[:space:]]*=' /etc/php.ini )" != "1" ]; then
	exit 1
fi

# Needed for PHP to read out docker-compose variables
run "sed -i'' 's/^variables_order[[:space:]]*=.*$/variables_order = EGPCS/g' /etc/php.ini"
grep -q '^variables_order = EGPCS$' /etc/php.ini
if [ "$( grep -c '^variables_order[[:space:]]*=' /etc/php.ini )" != "1" ]; then
	exit 1
fi



###
### Configure php-fpm.conf
###
print_headline "6. Configure php-fpm.conf"

# Lower loglevel to warning
run "sed -i'' 's|^;log_level[[:space:]]*=.*$|log_level = warning|g' ${PHP_FPM_CONF}"
grep -q '^log_level = warning$' "${PHP_FPM_CONF}"
if [ "$( grep -c '^log_level[[:space:]]*=' "${PHP_FPM_CONF}" )" != "1" ]; then
	exit 1
fi

# Set error log
if grep -q '^error_log[[:space:]]*=' "${PHP_FPM_CONF}"; then
	# shellcheck disable=SC2153
	run "sed -i'' 's|error_log[[:space:]]*=.*$|error_log = ${MY_LOG_FILE_FPM_ERR}|g' ${PHP_FPM_CONF}"
elif grep -q '^;error_log[[:space:]]*=' "${PHP_FPM_CONF}"; then
	run "sed -i'' 's|;error_log[[:space:]]*=.*$|error_log = ${MY_LOG_FILE_FPM_ERR}|g' ${PHP_FPM_CONF}"
else
	run "sed -i'' 's|\[global\]|[global]\nerror_log = ${MY_LOG_FILE_FPM_ERR}|g' ${PHP_FPM_CONF}"
fi
grep -q "^error_log = ${MY_LOG_FILE_FPM_ERR}$" "${PHP_FPM_CONF}"
if [ "$( grep -c '^error_log[[:space:]]*=' "${PHP_FPM_CONF}" )" != "1" ]; then
	exit 1
fi


run "sed -i'' 's|^daemonize.*||g' ${PHP_FPM_CONF}"
run "sed -i'' 's|\[global\]|[global]\ndaemonize = no|g' ${PHP_FPM_CONF}"
cat "${PHP_FPM_CONF}"


###
### Configure php-fpm Pool
###
print_headline "7. Configure php-fpm Pool"

# Set User
# user = apache
run "sed -i'' 's|^user[[:space:]]*=.*$|user = ${MY_USER}|g' ${PHP_FPM_POOL_CONF}"
grep -q "^user = ${MY_USER}$" "${PHP_FPM_POOL_CONF}"

# Set Group
# group = apache
run "sed -i'' 's|^group[[:space:]]*=.*$|group = ${MY_GROUP}|g' ${PHP_FPM_POOL_CONF}"
grep -q "^group = ${MY_GROUP}$" "${PHP_FPM_POOL_CONF}"

#
# Allow everybody to connect
run "sed -i'' 's|^listen.allowed_clients[[:space:]]*=.*$|; Removed listen allowed clients|g' ${PHP_FPM_POOL_CONF}"
if grep -q '^listen.allowed_clients[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	exit 1
fi

# Set Pool Access Log
# access.log = path
if grep -q '^access\.log[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|access\.log[[:space:]]*=.*$|access.log = ${MY_LOG_FILE_ACC}|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;[[:space:]]*access\.log[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|;[[:space:]]*access\.log[[:space:]]*=.*$|access.log = ${MY_LOG_FILE_ACC}|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\naccess.log = ${MY_LOG_FILE_ACC}|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q "^access\.log = ${MY_LOG_FILE_ACC}$" "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^access\.log[[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Set Pool Access Log format
# access.format = "[%t] %R - %u  \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"
if grep -q '^access\.format[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|access\.format[[:space:]]*=.*$|access.format = \"\[%{%d-%b-%Y:%H:%M:%S}t\] %R - \\\\\"%m %r%Q%q\\\\\" %s %f\"|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;[[:space:]]*access\.format[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|;[[:space:]]*access\.format[[:space:]]*=.*$|access.format = \"\[%{%d-%b-%Y:%H:%M:%S}t\] %R - \\\\\"%m %r%Q%q\\\\\" %s %f\"|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\naccess.format = \"\[%{%d-%b-%Y:%H:%M:%S}t\] %R - \\\\\"%m %r%Q%q\\\\\" %s %f\"|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q "^access\.format = \"\[%{%d-%b-%Y:%H:%M:%S}t\] %R - \\\\\"%m %r%Q%q\\\\\" %s %f\"$" "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^access\.format[[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Set Pool Slow Log
# slowlog = /path
if grep -q '^slowlog[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|slowlog[[:space:]]*=.*$|slowlog = ${MY_LOG_FILE_SLOW}|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;slowlog[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|;slowlog[[:space:]]*=.*$|slowlog = ${MY_LOG_FILE_SLOW}|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nslowlog = ${MY_LOG_FILE_SLOW}|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q "^slowlog = ${MY_LOG_FILE_SLOW}$" "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^slowlog[[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Enable slow logging
# request_slowlog_timeout = 0
if grep -q '^request_slowlog_timeout[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|request_slowlog_timeout[[:space:]]*=.*$|request_slowlog_timeout = 0|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;request_slowlog_timeout[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|;request_slowlog_timeout[[:space:]]*=.*$|request_slowlog_timeout = 0|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nrequest_slowlog_timeout = 0|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q "^request_slowlog_timeout = 0$" "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^request_slowlog_timeout[[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Set Pool Error Log
# php_admin_value[error_log] = /path
if grep -q '^php_admin_value\[error_log\][[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|php_admin_value\[error_log\][[:space:]]*=.*$|php_admin_value[error_log] = ${MY_LOG_FILE_ERR}|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;php_admin_value\[error_log\][[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|;php_admin_value\[error_log\][[:space:]]*=.*$|php_admin_value[error_log] = ${MY_LOG_FILE_ERR}|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nphp_admin_value[error_log] = ${MY_LOG_FILE_ERR}|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q "^php_admin_value\[error_log\] = ${MY_LOG_FILE_ERR}$" "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^php_admin_value\[error_log\][[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Enable Error Logging
# php_admin_flag[log_errors] = on
if grep -q '^php_admin_flag\[log_errors\][[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|php_admin_flag\[log_errors\][[:space:]]*=.*$|php_admin_flag[log_errors] = on|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;php_admin_flag\[log_errors\][[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|;php_admin_flag\[log_errors\][[:space:]]*=.*$|php_admin_flag[log_errors] = on|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nphp_admin_flag[log_errors] = on|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q "^php_admin_flag\[log_errors\] = on$" "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^php_admin_flag\[log_errors\][[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Enable unlimitted error logging length
# php_admin_value[log_errors_max_len] = 0
if grep -q '^php_admin_value\[log_errors_max_len\][[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|php_admin_value\[log_errors_max_len\][[:space:]]*=.*$|php_admin_value[log_errors_max_len] = 0|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;php_admin_value\[log_errors_max_len\][[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|;php_admin_value\[log_errors_max_len\][[:space:]]*=.*$|php_admin_value[log_errors_max_len] = 0|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nphp_admin_value[log_errors_max_len] = 0|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q "^php_admin_value\[log_errors_max_len\] = 0$" "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^php_admin_value\[log_errors_max_len\][[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Set Error log level
# php_value[error_reporting] = E_ALL
if grep -q '^php_value\[error_reporting\][[:space:]]*='; then
	run "sed -i'' 's|^php_value\[error_reporting\].*$|php_value[error_reporting] = E_ALL|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;php_value\[error_reporting\][[:space:]]*='; then
	run "sed -i'' 's|^;php_value\[error_reporting\].*$|php_value[error_reporting] = E_ALL|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nphp_value[error_reporting] = E_ALL|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q '^php_value\[error_reporting\] = E_ALL$' "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^php_value\[error_reporting\][[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Display errors
# php_flag[display_errors] = on
if grep -q '^php_flag\[display_errors\][[:space:]]*='; then
	run "sed -i'' 's|^php_flag\[display_errors\].*$|php_flag[display_errors] = on|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;php_flag\[display_errors\][[:space:]]*='; then
	run "sed -i'' 's|^;php_flag\[display_errors\].*$|php_flag[display_errors] = on|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nphp_flag[display_errors] = on|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q '^php_flag\[display_errors\] = on$' "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^php_flag\[display_errors\][[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Catch output of workers
# catch_workers_output = yes
if grep -q '^catch_workers_output[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|^catch_workers_output[[:space:]]*=.*$|catch_workers_output = yes|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;[[:space:]]*catch_workers_output[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|^;[[:space:]]*catch_workers_output[[:space:]]*=.*$|catch_workers_output = yes|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\ncatch_workers_output = yes|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q '^catch_workers_output = yes$' "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^catch_workers_output[[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Prevent PHP-FPM from clearing docker-compose environmental variables
# clear_env = no
if grep -q '^clear_env[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|^clear_env[[:space:]]*=.*$|clear_env = no|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;[[:space:]]*clear_env[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|^;[[:space:]]*clear_env[[:space:]]*=.*$|clear_env = no|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nclear_env = no|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q '^clear_env = no$' "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^clear_env[[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi

# Adding default listening directive
# listen = 0.0.0.0:9000
if grep -q '^listen[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|^listen[[:space:]]*=.*$|listen = 0.0.0.0:9000|g' ${PHP_FPM_POOL_CONF}"
elif grep -q '^;[[:space:]]*listen[[:space:]]*=' "${PHP_FPM_POOL_CONF}"; then
	run "sed -i'' 's|^;[[:space:]]*listen[[:space:]]*=.*$|listen = 0.0.0.0:9000|g' ${PHP_FPM_POOL_CONF}"
else
	run "sed -i'' 's|\[www\]|[www]\nlisten = 0.0.0.0:9000|g' ${PHP_FPM_POOL_CONF}"
fi
grep -q '^listen = 0.0.0.0:9000$' "${PHP_FPM_POOL_CONF}"
if [ "$( grep -c '^listen[[:space:]]*=' "${PHP_FPM_POOL_CONF}" )" != "1" ]; then
	exit 1
fi
cat "${PHP_FPM_POOL_CONF}"


###
### Create Log files
###
if [ ! -d "${MY_LOG_DIR}" ]; then
	run "mkdir -p ${MY_LOG_DIR}"
fi
if [ ! -f "${MY_LOG_FILE_ACC}" ]; then
	touch "${MY_LOG_FILE_ACC}"
fi
if [ ! -f "${MY_LOG_FILE_ERR}" ]; then
	touch "${MY_LOG_FILE_ERR}"
fi
if [ ! -f "${MY_LOG_FILE_SLOW}" ]; then
	touch "${MY_LOG_FILE_SLOW}"
fi
if [ ! -f "${MY_LOG_FILE_FPM_ERR}" ]; then
	touch "${MY_LOG_FILE_FPM_ERR}"
fi
if [ ! -f "${MY_LOG_FILE_XDEBUG}" ]; then
	touch "${MY_LOG_FILE_XDEBUG}"
fi
run "chmod 0755 ${MY_LOG_DIR}"
run "chmod -R 0644 ${MY_LOG_DIR}/*"
run "chown -R ${MY_USER}:${MY_GROUP} ${MY_LOG_DIR}"
