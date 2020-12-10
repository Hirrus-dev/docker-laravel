#!/bin/bash
    cd /docker-laravel/init

    if [ ! -d /docker-laravel/certbot ]
        then
            sudo docker-compose up -d
            while [ -z $(sudo docker ps -a -q  --filter "status=exited" --filter "name=certbot_init") ]
            do
                sleep 1
                echo waiting...
            done
            sudo docker-compose down

            sudo docker rmi $(sudo docker images -q)
            sudo docker volume rm $(sudo docker volume ls -q)
            cp -r ./certbot ../certbot
    fi