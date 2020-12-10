#!/bin/bash

    cd /docker-laravel/
    if [ -n "$(sudo docker ps -a -q)" ]
        then
            sudo docker stop $(sudo docker ps -a -q)
            sudo docker rm $(sudo docker ps -a -q)
    fi
    if [ -n "$(sudo docker images -q)" ]
        then
            sudo docker rmi $(sudo docker images -q)
    fi