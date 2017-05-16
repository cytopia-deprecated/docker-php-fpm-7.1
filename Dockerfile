##
## PHP-FPM 7.1
##
FROM centos:7
MAINTAINER "cytopia" <cytopia@everythingcli.org>


##
## Labels
##
LABEL \
	name="cytopia's PHP-FPM 7.1 Image" \
	image="php-fpm-7.1" \
	vendor="cytopia" \
	license="MIT" \
	build-date="2017-05-16"


###
### Envs
###

# User/Group
ENV MY_USER="devilbox"
ENV MY_GROUP="devilbox"
ENV MY_UID="1000"
ENV MY_GID="1000"

# User PHP config directories
ENV MY_CFG_DIR_PHP_CUSTOM="/etc/php-custom.d"

# Log files
ENV MY_LOG_DIR="/var/log/php"
ENV MY_LOG_FILE_ERR="${MY_LOG_DIR}/php-fpm.err"
ENV MY_LOG_FILE_XDEBUG="${MY_LOG_DIR}/xdebug.log"
ENV MY_LOG_FILE_POOL_ACC="${MY_LOG_DIR}/www-access.log"
ENV MY_LOG_FILE_POOL_ERR="${MY_LOG_DIR}/www-error.log"
ENV MY_LOG_FILE_POOL_SLOW="${MY_LOG_DIR}/www-slow.log"

ENV PHP_FPM_LOG_DIR="/var/log/php-fpm"
ENV PHP_FPM_POOL_LOG_ERR="/var/log/php-fpm/www-error.log"
ENV PHP_FPM_POOL_LOG_ACC="/var/log/php-fpm/www-access.log"
ENV PHP_FPM_POOL_LOG_SLOW="/var/log/php-fpm/www-slow.log"
ENV PHP_FPM_LOG_ERR="/var/log/php-fpm/php-fpm.err"
ENV PHP_LOG_XDEBUG="/var/log/php-fpm/xdebug.log"


###
### Install
###
RUN \
	groupadd -g ${MY_GID} -r ${MY_GROUP} && \
	adduser -u ${MY_UID} -m -s /bin/bash -g ${MY_GROUP} ${MY_USER}

RUN \
	yum -y install epel-release && \
	rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm && \
	yum-config-manager --enable remi && \
	yum-config-manager --disable remi-php55 && \
	yum-config-manager --disable remi-php56 && \
	yum-config-manager --disable remi-php70 && \
	yum-config-manager --enable remi-php71 && \
	yum clean all

RUN yum -y update && yum -y install \
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
	php-pear \
	php-pgsql \
	php-phalcon3 \
	php-pspell \
	php-recode \
	php-redis \
	php-soap \
	php-tidy \
	php-xml \
	php-xmlrpc \
	\
	php-pecl-apcu \
	php-pecl-imagick \
	php-pecl-memcache \
	php-pecl-memcached \
	php-pecl-uploadprogress \
	php-pecl-xdebug \
	php-pecl-zip \
	\
	postfix \
	\
	socat \
	\
	&& \
	\
	yum -y autoremove && \
	yum clean metadata && \
	yum clean all

##
## Install Tools
##
RUN yum -y update && yum -y install \
	bind-utils \
	which \
	git \
	nodejs \
	npm \
	\
	&& \
	\
	yum -y autoremove && \
	yum clean metadata && \
	yum clean all

RUN \
	curl -sS https://getcomposer.org/installer | php && \
	mv composer.phar /usr/local/bin/composer

RUN \
	git clone https://github.com/drush-ops/drush.git /usr/local/src/drush && \
	cd /usr/local/src/drush && \
	git checkout 8.1.11 && \
	composer --no-interaction --no-progress install && \
	ln -s /usr/local/src/drush/drush /usr/local/bin/drush

RUN \
	curl https://drupalconsole.com/installer -L -o drupal.phar && \
	mv drupal.phar /usr/local/bin/drupal && \
	chmod +x /usr/local/bin/drupal

RUN \
	rm -rf /root/.composer


##
## Bootstrap Scipts
##
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /
COPY ./scripts/bash-profile /etc/bash_profile


##
## Install
##
RUN /docker-install.sh


##
## Ports
##
EXPOSE 9000


##
## Volumes
##
VOLUME /var/log/php
VOLUME /etc/php-custom.d
VOLUME /var/mail


##
## Entrypoint
##
ENTRYPOINT ["/docker-entrypoint.sh"]
