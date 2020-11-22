#!/bin/bash

ssh_port=50142
user=mechanic
group=mechanic

if [ -z "$(grep -E "^$group:" /etc/group)" ]
    then
          sudo groupadd $group
fi

#20 Create user mechanic with password mecanic
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

sudo apt update &&\ 
sudo apt -y upgrade

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

#sudo apt -y install containerd &&\
#sudo apt -y install docker.io &&\
#sudo apt -y install docker-compose

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

#git clone https://github.com/Hirrus-dev/docker-laravel.git

#10 Change ssh port
#sudo sed -i "s/.*Port.*/Port $ssh_port/" /etc/ssh/sshd_config
##sed -i 's/#\?\(Port\s*\).*$/\1 50142/' /etc/ssh/sshd_config
#sudo systemctl restart sshd

#30 для добавления ключа ssh необходимо скопировать свой публичный ключ в файл ~/.ssh/authorized_keys
#35 для LEMP используются образы версий, указанные в файле docker-compose.yml
#37 имя БД, Пользователь и пароль БД указваются в файле docker-compose.yml. Внешние подключения исключены,
#   поскольку порты контейнера не пробрасываются наружу
#40 для запуска контейнров используется скрипт в папке ./scripts/init-dockerfile.sh.
#   Для смены имени сервера нужно поменять внутри скрипта имя переменной
