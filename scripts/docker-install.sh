#!/bin/sh -eu

###
### Variables
###
PHP_FPM_POOL_CONF="/etc/php-fpm.d/www.conf"
PHP_FPM_CONF="/etc/php-fpm.conf"

MY_USER="apache"
MY_GROUP="apache"
MY_UID="48"
MY_GID="48"


# Used to normalize directories between php and php-fpm
PHP_SESSION_SAVE_PATH="/var/lib/php/session"
PHP_SOAP_WSDL_CACHE_DIR="/var/lib/php/wsdlcache"
PHP_OPCACHE_FILE_CACHE="/var/lib/php/opcache"


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

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}


################################################################################
# MAIN ENTRY POINT
################################################################################


###
### Adding Users
###
print_headline "1. Adding Users"
run "groupadd -g ${MY_GID} -r ${MY_GROUP}"
run "adduser ${MY_USER} -u ${MY_UID} -M -s /sbin/nologin -g ${MY_GROUP}"



###
### Adding Repositories
###
print_headline "2. Adding Repository"
run "yum -y install epel-release"
run "rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
run "yum-config-manager --enable remi"
run "yum-config-manager --disable remi-php56"
run "yum-config-manager --disable remi-php70"
run "yum-config-manager --enable remi-php71"



###
### Updating Packages
###
print_headline "3. Updating Packages Manager"
run "yum clean all"
run "yum -y check"
run "yum -y update"



###
### Installing Packages
###
### (postfix provides /usr/sbin/sendmail)
###
print_headline "4. Installing Packages"
run "yum -y install \
	php \
	php-cli \
	php-fpm \
	\
	php-bcmath \
	php-common \
	php-gd \
	php-gmp \
	php-imap \
	php-intl \
	php-ldap \
	php-mbstring \
	php-mcrypt \
	php-mysql \
	php-mysqli \
	php-mysqlnd \
	php-opcache \
	php-pdo \
	php-pspell \
	php-recode \
	php-soap \
	php-tidy \
	php-xml \
	php-xmlrpc \
	\
	php-pecl-imagick \
	php-pecl-uploadprogress \
	php-pecl-xdebug \
	\
	postfix\
	"
# 	php-magickwand \



###
### Configure php.ini
###
print_headline "5. Configure php.ini"

# Fix fix_pathinfo (security precaution for php-fpm)
run "sed -i'' 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini"

# Needed for PHP to read out docker-compose variables
run "sed -i'' 's/^variables_order[[:space:]]*=.*$/variables_order = EGPCS/g' /etc/php.ini"



###
### Configure php-fpm.conf
###
print_headline "6. Configure php-fpm.conf"
# Lower loglevel to warning
run "sed -i'' 's|^;log_level[[:space:]]*=.*$|log_level = warning|g' ${PHP_FPM_CONF}"



###
### Configure php-fpm Pool
###
print_headline "7. Configure php-fpm Pool"

# Set User/Group
run "sed -i'' 's|^user[[:space:]]*=.*$|user = ${MY_USER}|g' ${PHP_FPM_POOL_CONF}"
run "sed -i'' 's|^group[[:space:]]*=.*$|group = ${MY_GROUP}|g' ${PHP_FPM_POOL_CONF}"
# Allow everybody to connect
run "sed -i'' 's|^listen.allowed_clients[[:space:]]*=.*$|; Removed listen allowed clients|g' ${PHP_FPM_POOL_CONF}"
# Set Logging
run "sed -i'' 's|;access.log[[:space:]]*=.*$|access.log = /var/log/php-fpm/\$pool-access.log|g' ${PHP_FPM_POOL_CONF}"
run "sed -i'' '/;access.format[[:space:]]*=.*$/s/^;//' ${PHP_FPM_POOL_CONF}"
run "sed -i'' 's|^;catch_workers_output[[:space:]]*=.*$|catch_workers_output = yes|g' ${PHP_FPM_POOL_CONF}"
# Prevent PHP-FPM from clearing docker-compose environmental variables
run "sed -i'' 's|^;clear_env[[:space:]]*=.*$|clear_env = no|g' ${PHP_FPM_POOL_CONF}"



###
### PHP/PHP-FPM Post fixes (tmp directories)
###
print_headline "8. PHP/PHP-FPM Post fixes (tmp directories)"

# Check Opcache file
if [ ! -f "/etc/php.d/10-opcache.ini" ]; then
	echo "Error, opcache config file not found in: /etc/php.d/10-opcache.ini"
	exit 1
fi

# PHP Adjust folders
run "sed -i'' 's|^;*session.save_path[[:space:]]*=.*$|session.save_path = \"${PHP_SESSION_SAVE_PATH}\"|g' /etc/php.ini"
run "sed -i'' 's|^;*soap.wsdl_cache_dir[[:space:]]*=.*$|soap.wsdl_cache_dir = \"${PHP_SOAP_WSDL_CACHE_DIR}\"|g' /etc/php.ini"
run "sed -i'' 's|^;*opcache.file_cache[[:space:]]*=.*$|opcache.file_cache = \"${PHP_OPCACHE_FILE_CACHE}\"|g' /etc/php.d/10-opcache.ini"

# PHP-FPM Adjust folders
run "sed -i'' 's|^;*php_value\[session.save_path\][[:space:]]*=.*$|php_value\[session.save_path\] = ${PHP_SESSION_SAVE_PATH}|g' ${PHP_FPM_POOL_CONF}"
run "sed -i'' 's|^;*php_value\[soap.wsdl_cache_dir\][[:space:]]*=.*$|php_value\[soap.wsdl_cache_dir\] = ${PHP_SOAP_WSDL_CACHE_DIR}|g' ${PHP_FPM_POOL_CONF}"
run "sed -i'' 's|^;*php_value\[opcache.file_cache\][[:space:]]*=.*$|php_value\[opcache.file_cache\] = ${PHP_OPCACHE_FILE_CACHE}|g' ${PHP_FPM_POOL_CONF}"

# Fix permissions
if [ ! -d "${PHP_SESSION_SAVE_PATH}" ]; then mkdir "${PHP_SESSION_SAVE_PATH}"; fi
if [ ! -d "${PHP_SOAP_WSDL_CACHE_DIR}" ]; then mkdir "${PHP_SOAP_WSDL_CACHE_DIR}"; fi
if [ ! -d "${PHP_OPCACHE_FILE_CACHE}" ]; then mkdir "${PHP_OPCACHE_FILE_CACHE}"; fi
run "chown -R ${MY_USER}:${MY_GROUP} ${PHP_SESSION_SAVE_PATH}"
run "chown -R ${MY_USER}:${MY_GROUP} ${PHP_SOAP_WSDL_CACHE_DIR}"
run "chown -R ${MY_USER}:${MY_GROUP} ${PHP_OPCACHE_FILE_CACHE}"
run "chmod 777  ${PHP_SESSION_SAVE_PATH}"
run "chmod 777  ${PHP_SOAP_WSDL_CACHE_DIR}"
run "chmod 777  ${PHP_OPCACHE_FILE_CACHE}"



###
### Installing Socat (for tunneling remote mysql to localhost)
###
print_headline "9. Installing Socat"
run "yum -y install socat"



###
### Cleanup unecessary packages
###
print_headline "10. Cleanup unecessary packages"
run "yum -y autoremove"
