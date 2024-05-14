FROM php:8.2-fpm-alpine as php

RUN apk update && apk add \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    git

RUN docker-php-ext-install pdo pdo_mysql

WORKDIR /var/www/html

RUN apk add yarn

COPY . /var/www/html/

COPY .env.example .env

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install --no-progress --no-dev --prefer-dist --optimize-autoloader --no-suggest

RUN chmod -R 777 storage bootstrap/cache

RUN chown -R www-data:www-data /var/www/html

RUN php artisan key:generate

RUN php artisan config:clear

RUN php artisan config:cache

RUN yarn

RUN php artisan storage:link

RUN yarn build