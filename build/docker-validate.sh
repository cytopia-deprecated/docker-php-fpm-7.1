#!/bin/sh -eu


# Be able to turn off debugging for docker start
DEBUG=0
DOCKER_LOGS=0
DOCKER_PS=0
if [ "${#}" = "1" ]; then
	if [ "${1}" = "1" ]; then
		DEBUG=1
	elif [ "${1}" = "2" ]; then
		DEBUG=1
		DOCKER_LOGS=1
		DOCKER_PS=1
	fi
fi

################################################################################
###
### GLOBAL VARS
###
################################################################################
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."

MY_DOCKER_NAME="my-php-docker"
MY_VERSION="$( grep 'image=".*"' "${CWD}/Dockerfile" | grep -Eo '[.0-9]+' )"

MY_CONF_DIR="$( mktemp -d )"
MY_SOCK_DIR="$( mktemp -d )"
MY_MAIL_DIR="$( mktemp -d )"
MY_HTML_DIR="$( mktemp -d )"
chmod 0777 "${MY_CONF_DIR}"
chmod 0777 "${MY_SOCK_DIR}"
chmod 0777 "${MY_MAIL_DIR}"
chmod 0777 "${MY_HTML_DIR}"

################################################################################
###
### FUNCTIONS
###
################################################################################
run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	echo
	printf "  ==> ${_red}%s \$ ${_green}$( echo "${_cmd}" | sed 's|%|%%|g' )${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
	echo
}
run_if() {
	_cmd="${1}"
	_true="${2}"
	_false="${3}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	echo
	printf "  ==> ${_red}%s \$ ${_green}$( echo "if ${_cmd}; then ${_true}; else ${_false}; fi" | sed 's|%|%%|g' )${_reset}\n" "${_user}"
	if 	sh -c "LANG=C LC_ALL=C ${_cmd}"; then
		echo
		eval "${_true}"
	else
		echo
		eval "${_false}"
	fi
}

wait_for() {
	_time="${1}"

	printf "wait "
	# shellcheck disable=SC2034
	for i in $(seq 1 "${_time}"); do
		sleep 1
		printf "."
	done
	printf "\n"
	return 0
}

print_h1() {
	printf "\033[0;36m%s\033[0m\n" "##############################################################################################################"
	printf "\033[0;36m%s\033[0m\n" "##############################################################################################################"
	printf "\033[0;36m%s\033[0m\n" "###                                                                                                        ###"
	printf "\033[0;36m%s %s\033[0m\n" "###" "${1}"
	printf "\033[0;36m%s\033[0m\n" "###                                                                                                        ###"
	printf "\033[0;36m%s\033[0m\n" "##############################################################################################################"
	printf "\033[0;36m%s\033[0m\n" "##############################################################################################################"
}

recreate_dirs() {
	if [ -d "${MY_CONF_DIR}" ]; then
		sudo rm -rf "${MY_CONF_DIR}" || true
	fi
	if [ -d "${MY_SOCK_DIR}" ]; then
		sudo rm -rf "${MY_SOCK_DIR}" || true
	fi
	if [ -d "${MY_MAIL_DIR}" ]; then
		sudo rm -rf "${MY_MAIL_DIR}" || true
	fi
	if [ -d "${MY_HTML_DIR}" ]; then
		sudo rm -rf "${MY_HTML_DIR}" || true
	fi
	MY_CONF_DIR="$( mktemp -d )"
	MY_SOCK_DIR="$( mktemp -d )"
	MY_MAIL_DIR="$( mktemp -d )"
	MY_HTML_DIR="$( mktemp -d )"

	chmod 0777 "${MY_CONF_DIR}"
	chmod 0777 "${MY_SOCK_DIR}"
	chmod 0777 "${MY_MAIL_DIR}"
	chmod 0777 "${MY_HTML_DIR}"
}

docker_start() {
	_args="${1}"
	docker_stop
	run "docker run -d --rm ${_args} --name ${MY_DOCKER_NAME} cytopia/${MY_DOCKER_NAME}"
	wait_for 10
	if [ "${DOCKER_LOGS}" = "1" ]; then
		run "docker logs $( docker_id )"
	fi
	if [ "${DOCKER_PS}" = "1" ]; then
		run "docker ps"
	fi
}
docker_exec() {
	_args="${1}"
	run "docker exec ${MY_DOCKER_NAME} ${_args}"
}
# Must return false
docker_exec_false() {
	_args="${1}"
	run_if "docker exec ${MY_DOCKER_NAME} ${_args}" "false" "true"
}
docker_stop() {
	run "docker stop $( docker_id ) >/dev/null 2>&1 || true"
	run "docker kill $( docker_id ) >/dev/null 2>&1 || true"
}
docker_logs() {
	run "docker logs $( docker_id )"
}
docker_id() {
	docker ps | grep "${MY_DOCKER_NAME}" | awk '{print $1}'
}
docker_start_mysql() {
	_args="${1}"
	docker_stop_mysql
	run "docker run -d --rm ${_args} --name mysql cytopia/mysql-5.5"
	wait_for 20
	if [ "${DOCKER_LOGS}" = "1" ]; then
		run "docker logs $( docker ps | grep 'mysql' | awk '{print $1}' )"
	fi
	if [ "${DOCKER_PS}" = "1" ]; then
		run "docker ps"
	fi
}
docker_stop_mysql() {
	run "docker stop $( docker ps | grep 'mysql' | awk '{print $1}' ) >/dev/null 2>&1 || true"
	run "docker kill $( docker ps | grep 'mysql' | awk '{print $1}' ) >/dev/null 2>&1 || true"
}
docker_start_httpd() {
	_args="${1}"
	docker_stop_httpd
	run "docker run -d --rm ${_args} --name httpd cytopia/nginx-stable"
	wait_for 20
	if [ "${DOCKER_LOGS}" = "1" ]; then
		run "docker logs $( docker ps | grep 'httpd' | awk '{print $1}' )"
	fi
	if [ "${DOCKER_PS}" = "1" ]; then
		run "docker ps"
	fi
}
docker_stop_httpd() {
	run "docker stop $( docker ps | grep 'httpd' | awk '{print $1}' ) >/dev/null 2>&1 || true"
	run "docker kill $( docker ps | grep 'httpd' | awk '{print $1}' ) >/dev/null 2>&1 || true"
}


################################################################################
###
### MAIN ENTRY POINT
###
################################################################################

############################################################
### [01] Build
############################################################
print_h1 "[01]   B U I L D I N G"
docker_stop >/dev/null 2>&1 || true
docker_stop_mysql >/dev/null 2>&1 || true
docker_stop_httpd >/dev/null 2>&1 || true
run "docker build -t cytopia/${MY_DOCKER_NAME} ${CWD}/"



############################################################
### [02] Test plain
############################################################
print_h1 "[02]   T E S T   P L A I N"

docker_start "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG}"
# Check version
docker_exec "php --version | grep 'PHP ${MY_VERSION}'"
# Check php-fpm is running
docker_exec "ps auxw | grep 'php-fpm'"
# Xdebug should be off
docker_exec_false "php -m | grep 'xdebug'"
# Socat should not be running
docker_exec_false "ps auxw | grep 'socat'"
# No custom configuration
docker_exec_false "php --ini | grep 'custom.ini'"
# Check timezone
docker_exec "php -r \"printf('%s', ini_get('date.timezone'));\" | grep 'UTC'"
docker_stop



############################################################
### [03] Timezone
############################################################
print_h1 "[03]   T I M E Z O N E"

docker_start "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -e TIMEZONE=Europe/Berlin"
# Check timezone
docker_exec "php -r \"printf('%s', ini_get('date.timezone'));\" | grep 'Europe/Berlin'"
docker_stop



############################################################
### [04] Xdebug
############################################################
print_h1 "[04]   X D E B U G"

docker_start "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -e PHP_XDEBUG_ENABLE=1 -e PHP_XDEBUG_REMOTE_HOST=127.0.0.1"
# Check Xdebug
docker_exec "php -m | grep 'xdebug'"
docker_exec "php -r \"printf('%s', ini_get('xdebug.default_enable'));\" | grep '1'"
docker_exec "php -r \"printf('%s', ini_get('xdebug.remote_host'));\" | grep '127.0.0.1'"
docker_exec "php -r \"printf('%s', ini_get('xdebug.remote_port'));\" | grep '9000'"
docker_stop



############################################################
### [05] Custom Config
############################################################
print_h1 "[05]  C U S T O M   C O N F I G"

recreate_dirs
run "printf \"[PHP]\\n%s\\n\" 'upload_max_filesize = 2048M' > ${MY_CONF_DIR}/custom.ini"
run "cat ${MY_CONF_DIR}/custom.ini"

docker_start "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -v ${MY_CONF_DIR}:/etc/php-custom.d"
# Check config
docker_exec "php -r \"printf('%s', ini_get('upload_max_filesize'));\" | grep -E '2048|2147483648'"
docker_stop



############################################################
### [06] MySQL Port forwarding
############################################################
print_h1 "[06]   M Y S Q L   P O R T   F O R W A R D I N G"

docker_start_mysql "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -e MYSQL_ROOT_PASSWORD="
docker_start "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -e FORWARD_PORTS_TO_LOCALHOST=3306:mysql:3306 --link mysql"
# Check for socket
docker_exec "ps auxw | grep socat"
# Test 127.0.0.1
docker_exec "php -r \"if (@mysqli_connect('127.0.0.1', 'root', '')) echo 'YES'; else echo 'NO';\" | grep 'YES'"
docker_exec "php -r \"if (@mysqli_connect('localhost', 'root', '')) echo 'YES'; else echo 'NO';\" | grep 'NO'"
docker_stop_mysql
docker_stop



############################################################
### [07] MySQL Socket mount
############################################################
print_h1 "[07]   M Y S Q L   S O C K E T   M O U N T"

recreate_dirs
# Start MySQL container
docker_start_mysql "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -e MYSQL_ROOT_PASSWORD= -e MYSQL_SOCKET_DIR=/tmp/mysql -v ${MY_SOCK_DIR}:/tmp/mysql"
# Create PHP config
run "printf \"[PHP]\\n%s\\n%s\\n%s\\n%s\\n\" 'mysql.default_socket = /tmp/mysql/mysqld.sock' 'mysqli.default_socket = /tmp/mysql/mysqld.sock' 'pdo_mysql.default_socket = /tmp/mysql/mysqld.sock' > ${MY_CONF_DIR}/custom.ini"
run "cat ${MY_CONF_DIR}/custom.ini"
# Start php container
docker_start "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -v ${MY_CONF_DIR}:/etc/php-custom.d -v ${MY_SOCK_DIR}:/tmp/mysql --link mysql"

# Test localhost
docker_exec "ls -lap /tmp/"
docker_exec "ls -lap /tmp/mysql/"
docker_exec "php -r \"print_r(ini_get_all());\" | grep -A 3 'default_socket\]'"
docker_exec "php -r \"if (@mysqli_connect('127.0.0.1', 'root', '')) echo 'YES'; else echo 'NO';\" | grep 'NO'"
docker_exec "php -r \"if (@mysqli_connect('localhost', 'root', '')) echo 'YES'; else echo 'NO';\" | grep 'YES'"
docker_stop_mysql
docker_stop



############################################################
### [08] Test Postfix mail delivery
############################################################
print_h1 "[08]   T E S T   P O S T F I X   M A I L"

recreate_dirs
docker_start "-e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -e ENABLE_MAIL=1 -v ${MY_MAIL_DIR}:/var/mail"

# Show dir
run "ls -lap ${MY_MAIL_DIR}/"
run "cat ${MY_MAIL_DIR}/devilbox"
# Send Mail
docker_exec "php -r \"mail('test@example.com', 'test-mail', 'the message');\""
# Show the queue
docker_exec "mailq"
wait_for 15
docker_exec "mailq"
# Show dir
run "ls -lap ${MY_MAIL_DIR}/"
run "cat ${MY_MAIL_DIR}/devilbox"
# Test for mail
run "grep 'test-mail' ${MY_MAIL_DIR}/devilbox"
docker_stop



############################################################
### [09] Test File Logs
############################################################
print_h1 "[09]   T E S T   F I L E   L O G S"

recreate_dirs
docker_start "-p 9000 -v ${MY_HTML_DIR}:/var/www/html -e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -e DOCKER_LOGS_ERROR=0 -e DOCKER_LOGS_ACCESS=0 -e DOCKER_LOGS_XDEBUG=0"
docker_start_httpd "-p 80:80 -v ${MY_HTML_DIR}:/var/www/html -e PHP_FPM_ENABLE=1 -e PHP_FPM_SERVER_ADDR=${MY_DOCKER_NAME} -e PHP_FPM_SERVER_PORT=9000 --link ${MY_DOCKER_NAME} -e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG}"

# Produce PHP error
echo "<?php echo echo include" > "${MY_HTML_DIR}/index.php"
run "curl localhost | grep 'syntax error'"
# Check logs (something must be in there)
docker_exec "ls -lap /var/log/php/"
docker_exec "find /var/log/php/ -type f -exec cat {} \\; | grep 'syntax error'"
# Check docker logs
docker_logs

docker_stop_httpd
docker_stop



############################################################
### [10] Test Docker Logs
############################################################
print_h1 "[10]   T E S T   D O C K E R   L O G S"

recreate_dirs
docker_start "-p 9000 -v ${MY_HTML_DIR}:/var/www/html -e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG} -e DOCKER_LOGS_ERROR=1 -e DOCKER_LOGS_ACCESS=1 -e DOCKER_LOGS_XDEBUG=1"
docker_start_httpd "-p 80:80 -v ${MY_HTML_DIR}:/var/www/html -e PHP_FPM_ENABLE=1 -e PHP_FPM_SERVER_ADDR=${MY_DOCKER_NAME} -e PHP_FPM_SERVER_PORT=9000 --link ${MY_DOCKER_NAME} -e DEBUG_COMPOSE_ENTRYPOINT=${DEBUG}"

# Produce PHP error
echo "<?php echo echo include" > "${MY_HTML_DIR}/index.php"
run "curl localhost | grep 'syntax error'"
# Check logs (nothing should be in there)
docker_exec "ls -lap /var/log/php/"
docker_exec_false "find /var/log/php/ -type f -exec cat {} \\; | grep 'syntax error'"
# Check docker logs
docker_logs

docker_stop_httpd
docker_stop
