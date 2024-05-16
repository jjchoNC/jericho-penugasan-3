FROM php:8.2-fpm-alpine as php

RUN apk update && apk add \
    curl \
    zip \
    unzip \
    git

RUN docker-php-ext-install pdo pdo_mysql

COPY . /var/www/html/

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install --working-dir=/var/www/html

RUN apk add yarn

COPY .env.example .env

RUN chmod -R 777 storage bootstrap/cache

RUN chown -R www-data:www-data /var/www/html