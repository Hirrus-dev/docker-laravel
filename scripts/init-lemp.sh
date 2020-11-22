#!/bin/bash

domain=".databridge.website"
name="dockertest"
domainname="$name$domain"
echo $domainname

cd ~/docker-laravel/scripts

sudo sed -i "s/localhost.localdomain/$domainname/" ../init/docker-compose.yml
sudo sed -i "s/localhost.localdomain/$domainname/" ../init/nginx/nginx-config

sudo sed -i "s/localhost.localdomain/$domainname/" ../nginx/nginx-config
sudo sed -i "s/localhost.localdomain/$domainname/" ../php-fpm/dockerfile
sudo sed -i "s/localhost.localdomain/$domainname/" ../docker-compose.yml

cd ~/docker-laravel/init

sudo docker-compose up -d
while [ -z $(sudo docker ps -a -q  --filter "status=exited" --filter "name=certbot") ]
do
    sleep 1
    echo waiting...
done
sudo docker-compose down

sudo docker rmi $(sudo docker images -q)
sudo docker volume rm $(sudo docker volume ls -q)
cp -r ./certbot ../certbot

cd ~/docker-laravel/

docker-compose up -d

mkdir ./nginx/public/laravel
#cd ~/docker-laravel/scripts
cd ./nginx/public/laravel
#git init
#git pull git@github.com:Hirrus-dev/laravel.git 6.x
#cd ../
#chown -R www-data:www-data ./laravel
#chmod 775 -R ./laravel
#composer update --no-scripts -d /var/www/dockertest.databridge.website/laravel/
#docker exec -it php bash -c "cp /.env /var/www/dockertest.databridge.website/laravel/.env"
#docker exec -it php bash -c "composer update --no-scripts -d /var/www/dockertest.databridge.website/laravel/"