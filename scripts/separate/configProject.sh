#!/bin/bash

if [ $# -eq 1 ]
then
    domain=".databridge.website"
    name=$1
    domainname="$name$domain"    
    sudo docker exec -it php bash -c "cp /.env /var/www/$domainname/laravel/.env"
    sudo docker exec -it php bash -c "composer update --no-scripts -d /var/www/$domainname/laravel/"
    sudo docker exec -it php bash -c "php artisan migrate"
    sudo crontab -l | { cat; echo "*/1 * * * * docker exec php bash -c \"cd /vaw/www/$domainname && sudo -u www-data artisan shedule:run\""; } | sudo crontab -
fi