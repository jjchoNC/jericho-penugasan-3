# Daftar Isi
1. [Dockerfile](#Dockerfile)
2. [Docker Container](#DockerContainer)
3. [CI/CD](#CICD)

---

## Dockerfile <a name="Dockerfile"></a>
Dockerfile berisikan perintah-perintah untuk membuat/membuild image baru. Dockerfile yang digunakan menggunakan base image dari `php-fpm:alpine versi 8.2` untuk image yang akan di build.

```yml
FROM php:8.2-fpm-alpine as php
```

Selanjutnya akan diunduh paket-paket yang dibutuhkan menggunakan instruksi di bawah.

```yml
RUN apk update && \
    apk add --no-cache \
        curl \
        zip \
        unzip \
        git \
        yarn && \
    docker-php-ext-install pdo pdo_mysql
```
Setelah berhasil terinstall, beberapa file yang dibutuhkan akan disalin ke direktori `/var/www/html` di dalam image yang akan dibuild.

```yml
COPY ./src/ /var/www/html/
WORKDIR /var/www/html
COPY .env.example /var/www/html/.env
```

Berikutnya, tool `Composer` akan diinstal dan instruksi `composer install` akan dijalankan untuk menginstall dependensi-dependensi yang disebutkan di `composer.json`.

```yml
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install --no-dev --no-interaction --no-progress --no-suggest --quiet
```

Instruksi selanjutnya adalah `RUN yarn && yarn build`. Yang mana `yarn` akan menginstall semua dependensi yang ada di `package.json`. Instruksi `yarn build` akan melakukan proses build pada projek web.

Jika semua sudah, perlu juga untuk melakukan pengaturan izin (`chmod`) dan kepemilikan file (`chown`).


