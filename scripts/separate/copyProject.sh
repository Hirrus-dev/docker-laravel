#!/bin/bash    
    cd /docker-laravel/nginx/public/laravel
    sudo rm -rf /docker-laravel/nginx/public/laravel/*
    if [ ! -d /docker-laravel/nginx/public/laravel/public ]
        then
            git init
            git pull git@github.com:Hirrus-dev/laravel.git 6.x
    fi

    cd /docker-laravel/nginx/public
    sudo chown -R www-data:www-data ./laravel
    sudo chmod 775 -R ./laravel