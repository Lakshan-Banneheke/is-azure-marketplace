#!/bin/bash

sudo apt-get update

sudo apt-get upgrade -y 

# Install Java

sudo NEEDRESTART_MODE=a apt install -y wget apt-transport-https
sudo mkdir -p /etc/apt/keyrings
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
echo deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo NEEDRESTART_MODE=a apt-get update
sudo NEEDRESTART_MODE=a apt install -y temurin-17-jdk=17.0.14.0.0+7-1
echo \"JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64\" | sudo tee -a /etc/environment
echo \"JAVA_HOME_17_X64=/usr/lib/jvm/temurin-17-jdk-amd64\" | sudo tee -a /etc/environment
export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64 >> ~/.zshrc
export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64 >> ~/.bashrc
source ~/.zshrc
source ~/.bashrc

# Install WSO2 IS
sudo apt-get install unzip -y
mkdir wso2is
cd wso2is/
wget https://github.com/wso2/product-is/releases/download/v7.1.0/wso2is-7.1.0.zip
unzip wso2is-7.1.0.zip
cd wso2is-7.1.0/bin/

# Install Nginx
sudo apt install nginx -y 

# Clone the artifact repo



# TODO: Clone the repo and cd to the folder containing the nginx config file
sudo cp is.http.conf /etc/nginx/conf.d/is.http.conf

## TODO generate the certificates and copy them to the /etc/ssl/localcerts/ folder

sudo service nginx reload


./wso2server.sh start