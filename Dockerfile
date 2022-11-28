###############################################################################################
# Limesurvey image
###############################################################################################
FROM php:8.1-apache as limesurvey

WORKDIR /var/www

RUN apt-get update
RUN apt-get install vim -y
RUN apt-get install net-tools -y

# based on https://gist.github.com/ben-albon/3c33628662dcd4120bf4
# based on https://github.com/adamzammit/limesurvey-docker/blob/master/Dockerfile
# install prerequisits
RUN apt-get install -y libpq-dev unzip libc-client-dev libfreetype6-dev libmcrypt-dev libpng-dev libjpeg-dev libldap2-dev zlib1g-dev libkrb5-dev libtidy-dev libzip-dev libsodium-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-freetype=/usr/include/  --with-jpeg=/usr \
	&& docker-php-ext-install gd mysqli pdo pdo_mysql pdo_pgsql opcache zip iconv tidy \
    && docker-php-ext-configure ldap --with-libdir=lib/$(gcc -dumpmachine)/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install imap \
    && docker-php-ext-install sodium \
    && pecl install mcrypt-1.0.4 \
    && docker-php-ext-enable mcrypt \
    && docker-php-ext-install exif

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# install limesurvey
RUN set -x; \
    curl -SL https://download.limesurvey.org/lts-releases/limesurvey3.26.1+210427.zip -o /tmp/lime.zip; \
    unzip /tmp/lime.zip -d /tmp; \
    mv /tmp/lime*/* /var/www/html/; \
    mv /tmp/lime*/.[a-zA-Z]* /var/www/html/; \
    rm /tmp/lime.zip; \
    rmdir /tmp/lime*; \
    chown -R www-data:www-data /var/www/html

#Set PHP defaults for Limesurvey (allow bigger uploads)
RUN { \
		echo 'memory_limit=256M'; \
		echo 'upload_max_filesize=128M'; \
		echo 'post_max_size=128M'; \
		echo 'max_execution_time=120'; \
        echo 'max_input_vars=10000'; \
        echo 'date.timezone=UTC'; \
	} > /usr/local/etc/php/conf.d/uploads.ini
