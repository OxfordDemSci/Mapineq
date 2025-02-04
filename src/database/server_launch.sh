# launch script to configure server

# hostname
sudo hostnamectl set-hostname mapineq-db

# update
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get autoremove -y && sudo reboot now

# postgres client
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
sudo apt update
sudo apt install postgresql-client-17

#---- docker ----#

# install docker
sudo apt-get install ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# add user to docker group
sudo usermod -aG docker ubuntu
newgrp docker


#---- github ----#
sudo apt install git

# create GitHub deploy key
cd ~/.ssh
ssh-keygen

#!! Remember to authorize the key on GitHub

# ssh config for github
echo "Host github" >> ~/.ssh/config
echo -e "\tHostName github.com" >> ~/.ssh/config
echo -e "\tUser git" >> ~/.ssh/config
echo -e "\tIdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config

# clone repository
cd ~
git clone git@github.com:OxfordDemSci/Mapineq

# deploy
cd ~/Mapineq
docker compose up -d --build



