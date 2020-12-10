#!/bin/bash

if [ $# -eq 1 ]
then
    domain=".databridge.website"
    name=$1
    domainname="$name$domain"    
    sudo docker exec -it php bash -c "cp /.env /var/www/$domainname/laravel/.env"
    sudo docker exec -it php bash -c "composer update --no-scripts -d /var/www/$domainname/laravel/"
    sudo docker exec -it php bash -c "php artisan migrate"
        croncmd="docker exec php bash -c \"cd /var/www/$domainname && sudo -u www-data php artisan schedule:run >> /dev/null 1>&1\""
        cronjob="*/1 * * * * $croncmd"
        ( sudo crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | sudo crontab -
fi