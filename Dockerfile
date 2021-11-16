### Designed as a Single Dockerfile for a base for all Laravel instances (app, worker, cron), not to be run alone.
### Notice the CMD is commented out.  Use this Docker image and extend it with 
### laravel packages (composer and npm) 
FROM php:7.4-fpm
# Override these vars with docker-compose, etc.
ENV NPM_ENV=prod \
    CONTAINER_ROLE=laravel \
    EXPOSED_PORT=80 \
    APP_NAME=laravel \
    MEMORY_LIMIT=2048M \
    MAX_EXECUTION_TIME=900 \
    MAX_POST_SIZE=20M \
    EXPOSE_PHP=0 \
    PHP_TIMEZONE=-UTC 

# Not sure if needed.
USER root

WORKDIR /var/www

# Install dependencies
RUN apt-get update \
    # packages
    && apt-get install -y --no-install-recommends \
        build-essential \
        nodejs \
        npm \
        openssl \
        nginx \
        curl \
        gifsicle \
        git \
        jpegoptim \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        locales \
        optipng \
        pngquant \
        unzip \
        vim \
        ca-certificates \
        cron \
        curl \
        gzip \
        libbsd0 \
        libbz2-1.0 \
        libc6 \
        libcom-err2 \
        libcurl4 \
        libldb-dev \
        libexpat1 \
        libfftw3-double3 \
        libfontconfig1 \
        libfreetype6 \
        libgcc1 \
        libgcrypt20 \
        libglib2.0-0 \
        libgmp10 \
        libgnutls30 \
        libgomp1 \
        libgpg-error0 \
        libgssapi-krb5-2 \
        libidn2-0 \
        libjpeg62-turbo \
        libk5crypto3 \
        libkeyutils1 \
        libkrb5-3 \
        libkrb5support0 \
        liblcms2-2 \
        libldap2-dev \
        liblqr-1-0 \
        libltdl7 \
        liblzma5 \
        libmagickcore-6.q16-6 \
        libmagickwand-6.q16-6 \
        libmcrypt4 \
        libmemcached11 \
        libmemcachedutil2 \
        libonig-dev \
        libncurses6 \
        libncursesw6 \
        libnghttp2-14 \
        libonig5 \
        libp11-kit0 \
        libpcre3 \
        libpng16-16 \
        libpq5 \
        libpsl5 \
        librtmp1 \
        libsasl2-2 \
        libsodium23 \
        libsqlite3-0 \
        libssh2-1 \
        libssl1.1 \
        libstdc++6 \
        libsybdb5 \
        libtasn1-6 \
        libtidy5deb1 \
        libtinfo6 \
        libunistring2 \
        libuuid1 \
        libwebp6 \
        libx11-6 \
        libxau6 \
        libxcb1 \
        libxdmcp6 \
        libxext6 \
        libxml2 \
        libxslt1.1 \
        libzip-dev \
        netcat \
        # php-redis \
        procps \
        sqlite3 \
        sudo \
        supervisor \
        tar \
        zlib1g \
        zip \
    #pecl apcu and reids for horizon, etc
    && pecl channel-update pecl.php.net \
    && pecl install apcu \
    && pecl install -o -f redis \
    #gd
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    # gmp
    && apt-get install -y --no-install-recommends libgmp-dev \
    && docker-php-ext-install gmp \
    # pdo_mysql
    && docker-php-ext-install pdo_mysql mbstring \
    # pdo
    && docker-php-ext-install pdo \
    # ldap
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install ldap \
    # opcache
    && docker-php-ext-enable opcache \
    # zip
    && docker-php-ext-install zip \
    #pcntl
    && docker-php-ext-install pcntl \
    #redis
    &&  docker-php-ext-enable redis \
    #exif
    && docker-php-ext-install exif \
    && docker-php-ext-enable exif \
    #cleanup
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/pear/


# Memory Limit, Time Zone, Display errors in stdout, Disable PathInfo, Disable expose PHP
RUN echo "memory_limit=${MEMORY_LIMIT}" > $PHP_INI_DIR/conf.d/memory-limit.ini \
    && echo "max_execution_time=${MAX_EXECUTION_TIME}" >> $PHP_INI_DIR/conf.d/memory-limit.ini \
    && echo "extension=apcu.so" > $PHP_INI_DIR/conf.d/apcu.ini \
    && echo "post_max_size=${MAX_POST_SIZE}" >> $PHP_INI_DIR/conf.d/memory-limit.ini \
    && echo "upload_max_filesize=${MAX_POST_SIZE}" >> $PHP_INI_DIR/conf.d/memory-limit.ini \
    && echo "date.timezone=${PHP_TIMEZONE}" > $PHP_INI_DIR/conf.d/date_timezone.ini \
    && echo "display_errors=stdout" > $PHP_INI_DIR/conf.d/display-errors.ini \
    && echo "cgi.fix_pathinfo=0" > $PHP_INI_DIR/conf.d/path-info.ini \
    && echo "expose_php=${EXPOSE_PHP}" > $PHP_INI_DIR/conf.d/path-info.ini


# Copy files
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./artisan-schedule-run /etc/cron.d/artisan-schedule-run
# COPY . /var/www

# Permissions for executables and nginx
RUN chmod +rwx /var/www \
    && chmod -R 777 /var/www \
    && touch /var/log/cron.log \
    # && chmod +x ./deploy/laravel/run_services_based_on_container_role.sh \
    && chmod 0644 /etc/cron.d/artisan-schedule-run \
    # Install NPM
    && npm install -g npm@latest \
    # Install Composer
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer 


EXPOSE $EXPOSED_PORT
# This image is a base, don't run unless you've uncommented below with desired installs for the laravel or php project
# the example script is included

# CMD [ "sh", "./deploy/laravel/run_services_based_on_container_role.sh" ]

