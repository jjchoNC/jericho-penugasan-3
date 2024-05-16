until docker exec mysql mysqladmin ping -h "localhost" --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 0.5
done

docker exec -i php php artisan config:clear
docker exec -i php php artisan storage:link
docker exec -i php php artisan key:generate
docker exec -i php php artisan migrate --seed
