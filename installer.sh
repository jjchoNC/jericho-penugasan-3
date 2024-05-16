until docker exec mysql mysqladmin ping -h "localhost" --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 1
done

docker exec -i php php artisan migrate --seed
php artisan config:clear
php artisan storage:link
php artisan key:generate
php artisan migrate --seed