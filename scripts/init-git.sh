#!/bin/bash

mkdir -p ~/.ssh/github
chmod 700 ~/.ssh ~/.ssh/github
ssh-keygen -t rsa -b 4096 -C 'your@email.com' -f ~/.ssh/github/id_rsa -q -N ''
touch ~/.ssh/config
chmod 600 ~/.ssh/config
cat << EOF | sudo tee /etc/nginx/sites-available/monit > /dev/null
Host github.com
    IdentityFile ~/.ssh/github/id_rsa
EOF

cat ~/.ssh/github/id_rsa.pub
echo "Paste this key to your github account"