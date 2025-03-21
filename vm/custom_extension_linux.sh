#!/bin/sh

sudo apt-get update

sudo apt-get upgrade -y

# Install Java
sudo NEEDRESTART_MODE=a apt install -y wget apt-transport-https
sudo mkdir -p /etc/apt/keyrings
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
echo deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo NEEDRESTART_MODE=a apt-get update
sudo NEEDRESTART_MODE=a apt install -y temurin-17-jdk=17.0.14.0.0+7-1
echo \"JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64\" | sudo tee -a /etc/environment
echo \"JAVA_HOME_17_X64=/usr/lib/jvm/temurin-17-jdk-amd64\" | sudo tee -a /etc/environment
export JAVA_HOME="/usr/lib/jvm/temurin-8-jdk-amd64"
echo "export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64" | sudo tee -a ~/.bashrc ~/.zshrc
source ~/.bashrc
source ~/.zshrc


# Install WSO2 IS
sudo apt-get install unzip -y
sudo apt-get install wget -y
mkdir /home/azureuser/wso2is
wget -P /home/azureuser/wso2is/ https://github.com/wso2/product-is/releases/download/v7.1.0/wso2is-7.1.0.zip
unzip -q /home/azureuser/wso2is/wso2is-7.1.0.zip -d /home/azureuser/wso2is/

# Install Nginx
sudo apt install nginx -y

# Clone the artifact repo and copy required files
git clone https://github.com/Lakshan-Banneheke/is-azure-marketplace.git
cd is-azure-marketplace/vm
sudo cp nginx/is.https.conf /etc/nginx/conf.d/is.https.conf
sudo cp is/deployment.toml /home/azureuser/wso2is/wso2is-7.1.0/repository/conf/deployment.toml

# Generate the certificates and copy them to the /etc/ssl/localcerts/ folder
sudo mkdir -p /etc/ssl/localcerts
sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/localcerts/is_public.key -out /etc/ssl/localcerts/is_public.crt -days 365 -nodes -subj "/C=US/ST=California/L=Santa Clara/O=WSO2/OU=IAM Department/CN=is.wso2"

# Generate the keystore with the localhost SAN and import the cert to the trustore
keytool -genkey -alias wso2carbon -keyalg RSA -keysize 2048 -keystore /home/azureuser/wso2is/wso2is-7.1.0/repository/resources/security/keystore.p12 -storetype PKCS12 -dname "CN=is.wso2, OU=IAM,O=WSO2,L=SantaClara,S=California,C=US" -storepass wso2carbon -keypass wso2carbon -ext SAN=dns:localhost
keytool -export -alias wso2carbon -keystore /home/azureuser/wso2is/wso2is-7.1.0/repository/resources/security/keystore.p12 -storetype PKCS12 -file /home/azureuser/wso2is/wso2is-7.1.0/repository/resources/security/pkn.pem -storepass wso2carbon -noprompt
keytool -import -alias newcert -file /home/azureuser/wso2is/wso2is-7.1.0/repository/resources/security/pkn.pem -keystore /home/azureuser/wso2is/wso2is-7.1.0/repository/resources/security/client-truststore.p12 -storetype PKCS12 -storepass wso2carbon -noprompt

# Reload Nginx
sudo service nginx reload

# Start the Identity Server
echo "Starting the WSO2 Identity Server"
/home/azureuser/wso2is/wso2is-7.1.0/bin/wso2server.sh start