# Daftar Isi
1. [Dockerfile](#Dockerfile)
2. [Docker Container](#DockerContainer)
3. [CI/CD](#CICD)
3. [Screenshoots](#Screenshoots)
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

## CI/CD <a name="CICD"></a>
Proses CI/CD menggunakan github actions dan terbagi menjadi 2 proses yaitu bulid + push docker image ke docker hub dan deploy ke server. Action CI/CD akan dilakuakn hanya ketika ada push ke branch main pada repositori dan file yang di push tidak merupakan `README.md`.

```yml
on:
  push:
    branches:
      - 'main'
    paths-ignore:
      - 'README.md'
```

Langkah pertama ax1dalah melakukan build + push docker image. Untuk melakukannya bisa menggunakan instruksi berikut.

```yml
docker:
    name: Docker
    permissions: write-all
    runs-on: ubuntu-latest
    steps:
      -
        name: Checkout
        uses: actions/checkout@v4
      -
        name: Set up QEMU
        uses: docker/setup-qemu-action@v3
      -
        name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      -
        name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      -
        name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/jericho-penugasan-3:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```
Pertama, proyek di-checkout menggunakan action `actions/checkout@v4` untuk mengambil kode-kode yang ada di repository. Selanjutnya, Docker Buildx diatur menggunakan action `docker/setup-buildx-action@v3` agar image yang dibuild nanti kompatibel dengan berbagai arsitektur. Setelah itu, perlu dilakukan action login ke docker hub menggunakan `docker/login-action@v3` dengan menyesuaikan username dan password. Untuk username dan password bisa dideklarasikan sebagai secrets. Selanjutnya, digunakan action `docker/build-push-action@v5`, pada langkah ini, Docker image dibuild dan kemudian dipush ke Docker Hub. Sebagai tambahan, cache digunakan untuk mempercepat proses build, dimana cache diambil dari dan disimpan ke dalam GitHub Actions (GHA) agar dapat digunakan kembali dalam build berikutnya.

Sangat penting untuk memisahkan file projek dan file-file lainnya yang tidak berhubungan. Karena cache tidak akan digunakan bila ada perubahan pada layer image, layer image perlu melakukan rebuilt, sehingga layer-layer selanjutnya tidak akan menggunakan cache. Kondisi ini sangat rawan apabila kita menggunakan instruksi `COPY . <dir>` pada Dockerfile, apabila file-file dijadikan satu maka sangat rawan untuk gagal menggunakan cache [[source](https://docs.docker.com/build/cache/)].

Setelah image berhasil dibuild dan dipush, sudah waktunya untuk dilakukan deploy ke server. Kali ini, saya menggunakan VM MS Azure yang nantinya terhubung melalui SSH.

```yml
deploy:
    name: Deploy
    needs: docker
    runs-on: ubuntu-latest
    steps:
        -
            name: Checkout
            uses: actions/checkout@v4
        - 
            name: Copy docker-compose.yml to remote server
            uses: appleboy/scp-action@v0.1.7
            with:
            host: ${{ secrets.HOST }}
            username: ${{ secrets.USERNAME }}
            key: ${{ secrets.PRIVATE_KEY }}
            port: ${{ secrets.PORT }}
            source: "./docker-compose.yml,./installer.sh,.nginx.conf"
            target: "."
        -
            name: executing remote ssh commands using private key
            uses: appleboy/ssh-action@v1.0.3
            with:
            host: ${{ secrets.HOST }}
            username: ${{ secrets.USERNAME }}
            key: ${{ secrets.PRIVATE_KEY }}
            port: ${{ secrets.PORT }}
            script: |
                docker pull ${{ secrets.DOCKERHUB_USERNAME }}/jericho-penugasan-3:latest
                docker compose up --force-recreate -d
                sh installer.sh
```

Proses deploy akan akan berjalan setelah proses build selesai. Sama dengan proses sebelumnya, langkah pertama yang dilakukan adalah melakukan checkout. Setelah melakukan checkout, file docker-compose.yml, installer.sh, dan nginx.conf perlu ada didalam VM. Oleh karena itu, untuk menyalinnya, bisa menggunakan action `appleboy/scp-action@v0.1.7` untuk melakukan transfer file melalui SSH. Setelah semua file diatas berhasil di transfer, kita perlu mengunduh image yang sudah dibuild dan memulai semua container yang sudah di setting pada docker-compose.yml. Untuk melakukannya kita perlu untuk masuk ke dalam VM melalui SSH, pada kasus ini kita bisa menggunakan action `appleboy/ssh-action@v1.0.3` dan melakukan perintah docker seperti di atas dan pastikan bahwa VM sudah terinstall Docker. 

Setelah image berhasil di pull dan semua container berhasil di muali, kita perlu melakukan migrasi database dan menanamkan data awal dengan perintah ( `php artisan migrate` ). Pada kasus ini perlu diperhatikan bahwa melakukan migrasi database berhubungan dengan dua container yaitu container `mysql` dan container `php`, agar tidak terjadi race condition, maka kita perlu menunggu service `mysql` siap dan barulah kita menjalankan proses di atas. Oleh karena itu, saya membuat script sederhana dengan melakukan `mysqladmin ping` hingga service mysql sudah siap.

```sh
until docker exec mysql mysqladmin ping -h "localhost" --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 0.5
done

docker exec -i php php artisan config:clear
docker exec -i php php artisan storage:link
docker exec -i php php artisan key:generate
docker exec -i php php artisan migrate --seed
```

Script tersebut akan dijalankan pada bagian paling akhir proses deployment.

## Screenshoot <a name="Screenshoots"></a>
