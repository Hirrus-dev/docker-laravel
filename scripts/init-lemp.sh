#!/bin/bash

domain=".google.com"
name="roman"
domainname="$name$domain"
echo $domainname

sed -i "s/localhost.localdomain/$domainname/" ../init/docker-compose.yml
sed -i "s/localhost.localdomain/$domainname/" ../init/nginx/nginx-config

sed -i "s/localhost.localdomain/$domainname/" ../nginx/nginx-config
sed -i "s/localhost.localdomain/$domainname/" ../docker-stage-2/docker-compose.yml

docker-compose up -f ../docker-stage-2/init/docker-compose.yml -d
while(sudo docker ps -a -q  --filter "status=exited" --filter "name=certbot"){
    sleep 1
}
docker-compose down -f ../init/docker-compose.yml

cp -r ../init/certbot ../certbot

docker-compose up -f ../docker-compose.yml


#composer update --no-scripts -d /var/www/dockertest.databridge.website/laravel/