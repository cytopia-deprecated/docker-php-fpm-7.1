###
### PHP-FPM 7.1
###
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
	build-date="2017-06-07"


###
### Envs
###

# User/Group
ENV MY_USER="devilbox" \
	MY_GROUP="devilbox" \
	MY_UID="1000" \
	MY_GID="1000"

# User PHP config directories
ENV MY_CFG_DIR_PHP_CUSTOM="/etc/php-custom.d"

# Log Files
ENV MY_LOG_DIR="/var/log/php" \
	MY_LOG_FILE_XDEBUG="/var/log/php/xdebug.log" \
	MY_LOG_FILE_ACC="/var/log/php/www-access.log" \
	MY_LOG_FILE_ERR="/var/log/php/www-error.log" \
	MY_LOG_FILE_SLOW="/var/log/php/www-slow.log" \
	MY_LOG_FILE_FPM_ERR="/var/log/php/php-fpm.err"


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
	php-pecl-mongodb \
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

###
### Install Tools
###
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
	mkdir -p /usr/local/src && \
	chown ${MY_USER}:${MY_GROUP} /usr/local/src && \
	su - ${MY_USER} -c 'git clone https://github.com/drush-ops/drush.git /usr/local/src/drush' && \
	su - ${MY_USER} -c 'cd /usr/local/src/drush && git checkout 8.1.11' && \
	su - ${MY_USER} -c 'cd /usr/local/src/drush && composer install --no-interaction --no-progress' && \
	ln -s /usr/local/src/drush/drush /usr/local/bin/drush

RUN \
	curl https://drupalconsole.com/installer -L -o drupal.phar && \
	mv drupal.phar /usr/local/bin/drupal && \
	chmod +x /usr/local/bin/drupal


###
### Bootstrap Scipts
###
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /
COPY ./scripts/bash-profile /etc/bash_profile


###
### Install
###
RUN /docker-install.sh


###
### Ports
###
EXPOSE 9000


###
### Volumes
###
VOLUME /var/log/php
VOLUME /etc/php-custom.d
VOLUME /var/mail


###
### Entrypoint
###
ENTRYPOINT ["/docker-entrypoint.sh"]
