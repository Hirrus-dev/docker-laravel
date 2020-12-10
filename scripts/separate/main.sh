#!/bin/bash

if [ $# -eq 1 ]
then
    sudo ./prepareOS.sh $1
    sudo ./getFirstCert.sh
    sudo ./cleanDocker.sh
    sudo ./startDocker.sh
    sudo ./copyProject.sh
    sudo .configProject.sh $1
fi