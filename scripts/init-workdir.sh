#!/bin/bash

cd ~/docker-laravel/nginx/public
sudo chown -R www-data:www-data ./laravel
sudo chmod 775 -R ./laravel
sudo composer update --no-scripts -d /var/www/dockertest.databridge.website/laravel/
sudo docker exec -it php bash -c "cp /.env /var/www/dockertest.databridge.website/laravel/.env"
sudo docker exec -it php bash -c "composer update --no-scripts -d /var/www/dockertest.databridge.website/laravel/"