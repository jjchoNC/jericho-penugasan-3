FROM php:8.2-fpm-alpine as php

RUN apk update && apk add \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    git

RUN docker-php-ext-install pdo pdo_mysql \
    && apk --no-cache add nodejs npm

WORKDIR /var/www/html

RUN apk add --no-cache yarn

COPY . /var/www/html/

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install

RUN chmod 775 -R .

RUN chown -R www-data:www-data .

RUN php artisan key:generate

RUN php artisan config:clear

RUN php artisan config:cache

RUN yarn

RUN yarn build