#!/bin/bash

if [ $# -eq 1 ]
then

    ssh_port=50142
    user=mechanic
    group=mechanic

    domain=".databridge.website"
    name=$1

    if [ -z "$(grep -E "^$group:" /etc/group)" ]
        then
            sudo groupadd $group
    fi

    if [ -z "$(grep -E "www-data:" /etc/group)" ]
        then
            sudo groupadd www-data
    fi

    #20 Create user mechanic with password mechanic
    if [ -z "$(grep -E "^$user:" /etc/passwd)" ]
        then
            sudo useradd $user -g $group -s /bin/bash -d /home/$user -p $(openssl passwd -6 mechanic)
    fi

    if ! [ -d /home/$user ]
        then
            sudo mkdir /home/$user/
    fi

    sudo chown -R $user:$group /home/$user

    usermod -aG sudo $user
    usermod -aG www-data $user

    sudo apt update && apt upgrade -y

    if [ -z $(which containerd) ]
        then
            sudo apt install -y containerd
    fi

    if [ -z $(which docker) ]
        then
            sudo apt install -y docker
    fi

    if [ -z $(which docker-compose) ]
        then
            sudo apt install -y docker-compose
    fi

    if [ -e /var/run/docker.pid ]
        then
            systemctl unmask docker
            systemctl start docker
    fi

    #70 SWAPfile
    sudo fallocate -l 1.5G /swapfile
    sudo chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

    #10 Change ssh port
    sudo sed -i "s/.*Port.*/Port $ssh_port/" /etc/ssh/sshd_config
    ##sed -i 's/#\?\(Port\s*\).*$/\1 50142/' /etc/ssh/sshd_config
    sudo systemctl restart sshd

#30 для добавления ключа ssh необходимо скопировать свой публичный ключ в файл ~/.ssh/authorized_keys
#35 для LEMP используются образы версий, указанные в файле docker-compose.yml
#37 имя БД, Пользователь и пароль БД указваются в файле docker-compose.yml. Внешние подключения исключены,
#   поскольку порты контейнера не пробрасываются наружу
#40 для запуска контейнров используется скрипт в папке ./scripts/init-dockerfile.sh.
#   Для смены имени сервера нужно поменять внутри скрипта имя переменной


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
    cp ~/.env ~/docker-laravel/php-fpm

    docker-compose up -d

    cd ~/docker-laravel/nginx/public/laravel
    git init
    git pull git@github.com:Hirrus-dev/laravel.git 6.x

    cd ~/docker-laravel/nginx/public
    sudo chown -R www-data:www-data ./laravel
    sudo chmod 775 -R ./laravel
    sudo docker exec -it php bash -c "cp /.env /var/www/dockertest.databridge.website/laravel/.env"
    sudo docker exec -it php bash -c "composer update --no-scripts -d /var/www/dockertest.databridge.website/laravel/"
fi