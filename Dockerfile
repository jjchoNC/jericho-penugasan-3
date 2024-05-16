FROM php:8.2-fpm-alpine as php

RUN apk update && apk add \
    curl \
    zip \
    unzip \
    git

RUN docker-php-ext-install pdo pdo_mysql

WORKDIR /var/www/html

RUN apk add yarn

COPY . /var/www/html/

COPY .env.example .env

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN --mount=type=cache,target=/root/.composer/cache composer install

RUN chmod -R 777 storage bootstrap/cache

RUN chown -R www-data:www-data /var/www/html