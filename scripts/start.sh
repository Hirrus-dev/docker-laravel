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
            sudo mkdir /home/$user
    fi

    if ! [ -d /home/$user/.ssh ]
        then
            sudo mkdir /home/$user/.ssh
    fi

    if ! [ -d /home/$user/.ssh/github ]
        then
            sudo mkdir -p /home/$user/.ssh/github
    fi
    

    if [ -f /home/$user/.ssh/authorized_keys ]
        then
            if [ -z "$(grep  "$(cat /docker-laravel/key/id_rsa.pub)" /home/$user/.ssh/authorized_keys)" ]
                then
                    cat /docker-laravel/key/id_rsa.pub >> /home/$user/.ssh/authorized_keys
            fi
        else
            cp /docker-laravel/key/id_rsa.pub /home/$user/.ssh/authorized_keys
    fi

    sudo chown -R $user:$group /home/$user
    sudo chmod 700 /home/$user/.ssh /home/$user/.ssh/github

    usermod -aG sudo $user
    usermod -aG www-data $user

    sudo apt update && apt upgrade -y

    if [ -z $(which git) ]
        then
            sudo apt install -y git
    fi
    
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


    if ! [ -d ~/.ssh/github ]
        then
            sudo mkdir -p ~/.ssh/github
    fi
    
    sudo chmod 700 ~/.ssh ~/.ssh/github

    # Add private key for repo

#    if [ -f ~/.ssh/github/id_rsa ]
#        then
#            if [ ! -s ~/.ssh/github/id_rsa ]
#                then
#                    sudo rm -f ~/.ssh/github/id_rsa
#            fi
#    fi

    if   [ -f /docker-laravel/key/id_rsa ]
        then    
            if [ -s /docker-laravel/key/id_rsa ]
                then
                    sudo cp -f /docker-laravel/key/id_rsa ~/.ssh/github/id_rsa
                    sudo cp -f /docker-laravel/key/id_rsa /home/$user/.ssh/github/id_rsa
                else
                    echo "Private key file /docker-laravel/key/id_rsa is empty"
            fi
        else
            echo "Not found file private key in /docker-laravel/key/id_rsa"
    fi

    if [ -f ~/.ssh/github/id_rsa ]
        then
            if ! [ -s ~/.ssh/github/id_rsa ]
                then
                    echo "Private key file ~/.ssh/github/id_rsa is empty"
                    exit 0
            fi
        else
            echo "Private key file ~/.ssh/github/id_rsa is absent"
            exit 0
    fi
 

    sudo chown $USER: ~/.ssh/github/id_rsa
    sudo chmod 600 ~/.ssh/github/id_rsa

    sudo chown $user /home/$user/.ssh/github/id_rsa
    sudo chmod 600 /home/$user/.ssh/github/id_rsa

    if ! [ -f ~/.ssh/config ]
        then
            sudo touch ~/.ssh/config
    fi
    sudo chmod 600 ~/.ssh/config
    if [ -z "$(grep -E "^Host github.com" ~/.ssh/config)" ]
        then
            cat << EOF | sudo tee ~/.ssh/config > /dev/null
    Host github.com
        IdentityFile ~/.ssh/github/id_rsa
EOF
    fi

    #70 SWAPfile
    sudo fallocate -l 1.5G /swapfile
    sudo chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    if [ -z "$(grep -E "/swapfile none swap sw 0 0" /etc/fstab)" ]
        then
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi

    

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

    cd /docker-laravel/scripts

    sudo sed -i "s/localhost.localdomain/$domainname/" ../init/docker-compose.yml
    sudo sed -i "s/localhost.localdomain/$domainname/" ../init/nginx/nginx-config

    sudo sed -i "s/localhost.localdomain/$domainname/" ../nginx/nginx-config
    sudo sed -i "s/localhost.localdomain/$domainname/" ../php-fpm/dockerfile
    sudo sed -i "s/localhost.localdomain/$domainname/" ../docker-compose.yml

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

    cd /docker-laravel/
    #cp ~/.env ~/docker-laravel/php-fpm
    if [ -n "$(sudo docker ps -a -q)" ]
        then
            sudo docker stop $(sudo docker ps -a -q)
            sudo docker rm $(sudo docker ps -a -q)
    fi
    if [ -n "$(sudo docker images -q)" ]
        then
            sudo docker rmi $(sudo docker images -q)
    fi

    sudo docker-compose up -d

    cd /docker-laravel/nginx/public/laravel
    if [ ! -d /docker-laravel/nginx/public/laravel/public ]
        then
            git init
            git pull git@github.com:Hirrus-dev/laravel.git 6.x
    fi

    cd /docker-laravel/nginx/public
    sudo chown -R www-data:www-data ./laravel
    sudo chmod 775 -R ./laravel
    sudo docker exec -it php bash -c "cp /.env /var/www/$domainname/laravel/.env"
    sudo docker exec -it php bash -c "composer update --no-scripts -d /var/www/$domainname/laravel/"
fi
