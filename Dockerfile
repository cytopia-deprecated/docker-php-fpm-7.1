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
	build-date="2017-06-18"


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
	rpm -ivh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm && \
	yum-config-manager --enable pgdg96 && \
	( \
		echo "[mongodb-org-3.2]"; \
		echo "name=MongoDB Repository"; \
		echo "baseurl=https://repo.mongodb.org/yum/redhat/7Server/mongodb-org/3.2/x86_64/"; \
		echo "gpgcheck=1"; \
		echo "enabled=1"; \
		echo "gpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc"; \
	) > /etc/yum.repos.d/mongodb.repo && \
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
	mysql \
	postgresql96 \
	mongodb-org-tools \
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
	mv composer.phar /usr/local/bin/composer && \
	composer self-update

RUN \
	DRUSH_VERSION="$( curl -q https://api.github.com/repos/drush-ops/drush/releases 2>/dev/null | grep tag_name | grep -Eo '\"[0-9.]+\"' | head -1 | sed 's/\"//g' )" && \
	mkdir -p /usr/local/src && \
	chown ${MY_USER}:${MY_GROUP} /usr/local/src && \
	su - ${MY_USER} -c 'git clone https://github.com/drush-ops/drush.git /usr/local/src/drush' && \
	v="${DRUSH_VERSION}" su ${MY_USER} -p -c 'cd /usr/local/src/drush && git checkout ${v}' && \
	su - ${MY_USER} -c 'cd /usr/local/src/drush && composer install --no-interaction --no-progress' && \
	ln -s /usr/local/src/drush/drush /usr/local/bin/drush

RUN \
	curl https://drupalconsole.com/installer -L -o drupal.phar && \
	mv drupal.phar /usr/local/bin/drupal && \
	chmod +x /usr/local/bin/drupal

RUN \
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp && \
	chmod +x /usr/local/bin/wp && \
	wp cli update

RUN \
	mkdir -p /usr/local/src && \
	chown ${MY_USER}:${MY_GROUP} /usr/local/src && \
	su - ${MY_USER} -c 'git clone https://github.com/cytopia/mysqldump-secure.git /usr/local/src/mysqldump-secure' && \
	su - ${MY_USER} -c 'cd /usr/local/src/mysqldump-secure && git checkout $(git describe --abbrev=0 --tags)' && \
	ln -s /usr/local/src/mysqldump-secure/bin/mysqldump-secure /usr/local/bin && \
	cp /usr/local/src/mysqldump-secure/etc/mysqldump-secure.conf /etc && \
	cp /usr/local/src/mysqldump-secure/etc/mysqldump-secure.cnf /etc && \
	touch /var/log/mysqldump-secure.log && \
	chown ${MY_USER}:${MY_GROUP} /etc/mysqldump-secure.* && \
	chown ${MY_USER}:${MY_GROUP} /var/log/mysqldump-secure.log && \
	chmod 0400 /etc/mysqldump-secure.conf && \
	chmod 0400 /etc/mysqldump-secure.cnf && \
	chmod 0644 /var/log/mysqldump-secure.log && \
	sed -i'' 's/^DUMP_DIR=.*/DUMP_DIR="\/shared\/backups\/mysql"/g' /etc/mysqldump-secure.conf && \
	sed -i'' 's/^DUMP_DIR_CHMOD=.*/DUMP_DIR_CHMOD="0755"/g' /etc/mysqldump-secure.conf && \
	sed -i'' 's/^DUMP_FILE_CHMOD=.*/DUMP_FILE_CHMOD="0644"/g' /etc/mysqldump-secure.conf && \
	sed -i'' 's/^LOG_CHMOD=.*/LOG_CHMOD="0644"/g' /etc/mysqldump-secure.conf && \
	sed -i'' 's/^NAGIOS_LOG=.*/NAGIOS_LOG=0/g' /etc/mysqldump-secure.conf


###
### Configure PS1
###
RUN \
	echo ". /etc/bash_profile" >> /home/${MY_USER}/.bashrc && \
	echo ". /etc/bash_profile" >> /root/.bashrc


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
