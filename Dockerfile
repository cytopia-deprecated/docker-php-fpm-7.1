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
	build-date="2017-04-19"


###
### Envs
###

# User/Group
ENV MY_USER="apache"
ENV MY_GROUP="apache"
ENV MY_UID="48"
ENV MY_GID="48"

# Log files
ENV PHP_FPM_LOG_DIR="/var/log/php-fpm"
ENV PHP_FPM_POOL_LOG_ERR="/var/log/php-fpm/www-error.log"
ENV PHP_FPM_POOL_LOG_ACC="/var/log/php-fpm/www-access.log"
ENV PHP_FPM_POOL_LOG_SLOW="/var/log/php-fpm/www-slow.log"
ENV PHP_FPM_LOG_ERR="/var/log/php-fpm/php-fpm.err"
ENV PHP_LOG_XDEBUG="/var/log/php-fpm/xdebug.log"


###
### Install
###
RUN groupadd -g ${MY_GID} -r ${MY_GROUP} &&\
	adduser ${MY_USER} -u ${MY_UID} -M -s /sbin/nologin -g ${MY_GROUP}

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
	php-pecl-uploadprogress \
	php-pecl-xdebug \
	\
	postfix \
	\
	socat

RUN \
	yum -y autoremove && \
	yum clean metadata && \
	yum clean all


##
## Bootstrap Scipts
##
COPY ./scripts/docker-install.sh /
COPY ./scripts/docker-entrypoint.sh /


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
VOLUME /var/log/php-fpm
VOLUME /etc/php-custom.d
VOLUME /var/mail


##
## Entrypoint
##
ENTRYPOINT ["/docker-entrypoint.sh"]
