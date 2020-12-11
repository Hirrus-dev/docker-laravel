#!/bin/bash

if [ $# -eq 1 ]
then
    sudo /docker-laravel/scripts/separate/prepareOS.sh $1
    sudo /docker-laravel/scripts/separate/getFirstCert.sh
    sudo /docker-laravel/scripts/separate/cleanDocker.sh
    sudo /docker-laravel/scripts/separate/startDocker.sh
    sudo /docker-laravel/scripts/separate/copyProject.sh
    sudo /docker-laravel/scripts/separate/configProject.sh $1
fi