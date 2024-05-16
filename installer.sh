function wait_for_mysql() {
  while ! mysqladmin ping -h "localhost" --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 1
  done
  echo "MySQL is up and running!"
}

wait_for_mysql
php artisan config:clear
php artisan storage:link
php artisan key:generate
php artisan migrate --seed