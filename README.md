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


## Docker Container <a name="DockerContainer"></a>
Terdapat 3 container, yaitu container `mysql`, `php`, dan `nginx`. Container `mysql`berguna untuk mengatur/menyiapakan database yang nanti akan digunakan pada projek. Untuk nama database dan juga nama host dideklarasikan pada bagian `environment`.

Selanjutnya, container `php` berguna untuk menjalankan aplikasi web (BE & FE). Container `php` baru akan berjalan setelah container `mysql` dijalankan karena digunakannya kondisi `depends-on`. Container ini menggunakan image dari image hasil build Dockerfile dan service container akan dimulai ulang hanya jika mengalmai kondisi error.

Container terakhir yang digunakan adalag container `nginx` yang bertindak sebagai reverse proxy. Jalannya container ini bergantung kepada container `mysql` dan `php`. Selain itu, container ini juga menggunakan `volume` untuk berbagi data dan juga untk mengaitkan file konfigurasi nginx dari lokal  ke kontainer.

Perlu diingat bahwa semua container berjalan pada networks yang sama, yaitu network `laravel-net`.