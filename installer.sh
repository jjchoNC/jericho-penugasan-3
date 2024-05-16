echo "Running composer install..."
composer install
if [ $? -ne 0 ]; then
  echo "composer install failed"
  exit 1
fi

echo "Running php artisan migrate..."
php artisan migrate --seed
if [ $? -ne 0 ]; then
  echo "migration failed"
  exit 1
fi

echo "Running yarn..."
yarn
if [ $? -ne 0 ]; then
  echo "yarn failed"
  exit 1
fi

echo "Running yarn build..."
yarn build
if [ $? -ne 0 ]; then
  echo "yarn build failed"
  exit 1
fi

echo "Running php
php artisan key:generate
if [ $? -ne 0 ]; then
  echo "php artisan
  exit 1
fi

echo "Running php artisan config:clear..."
php artisan config:clear
if [ $? -ne 0 ]; then
  echo "php artisan config:clear failed"
  exit 1
fi

echo "Running php artisan config:cache..."
php artisan config:cache
if [ $? -ne 0 ]; then
  echo "php artisan config:cache failed"
  exit 1
fi

echo "Running php artisan route:clear..."
php artisan storage:link
if [ $? -ne 0 ]; then
  echo "php artisan storage:link failed"
  exit 1
fi