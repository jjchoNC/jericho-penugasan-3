FROM php:8.2-fpm-alpine as php

RUN apk update && \
    apk add --no-cache \
        curl \
        zip \
        unzip \
        git \
        yarn && \
    docker-php-ext-install pdo pdo_mysql

COPY ./src/ /var/www/html/
WORKDIR /var/www/html

COPY .env.example /var/www/html/.env

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install --no-dev --no-interaction --no-progress --no-suggest --quiet

RUN yarn && yarn build

RUN chmod -R 777 storage bootstrap/cache && \
    chown -R www-data:www-data /var/www/html