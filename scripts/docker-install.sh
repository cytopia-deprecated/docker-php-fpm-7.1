#!/bin/sh -eu

###
### Variables
###
PHP_FPM_POOL_CONF="/etc/php-fpm.d/www.conf"
PHP_FPM_CONF="/etc/php-fpm.conf"

# Custom php directory to look for *.ini files
PHP_CUST_CONF_DIR="/etc/php-custom.d"

MY_USER="apache"
MY_GROUP="apache"
MY_UID="48"
MY_GID="48"



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
run "yum-config-manager --disable remi-php55"
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
	php-pecl-apcu \
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

# Add custom php configuration directory
if [ ! -d "${PHP_CUST_CONF_DIR}" ]; then
	run "mkdir -p ${PHP_CUST_CONF_DIR}"
fi



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
# Adding default listening directive
run "sed -i'' 's|^listen[[:space:]]*=.*$|listen = 0.0.0.0:9000|g' ${PHP_FPM_POOL_CONF}"



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
run "yum clean all"
