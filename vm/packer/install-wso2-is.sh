#!/bin/bash

USER=wso2carbon
USER_ID=10001
USER_HOME=/home/${USER}
EXTRACT_DIR="$USER_HOME/wso2is/"

sudo useradd --system --create-home --home-dir ${USER_HOME} --no-log-init -u ${USER_ID} ${USER}

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install unzip -y
sudo apt-get install wget -y
sudo apt-get install nginx -y

# Install Java
sudo NEEDRESTART_MODE=a apt install -y wget apt-transport-https
sudo mkdir -p /etc/apt/keyrings
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
echo deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo NEEDRESTART_MODE=a apt-get update
sudo NEEDRESTART_MODE=a apt install -y temurin-17-jdk=17.0.14.0.0+7-1
echo \"JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64\" | sudo tee -a /etc/environment
echo \"JAVA_HOME_17_X64=/usr/lib/jvm/temurin-17-jdk-amd64\" | sudo tee -a /etc/environment

# Install WSO2 IS
echo "### Installing WSO2 Identity Server ###"
echo "Creating the directory"
sudo -u $USER mkdir $USER_HOME/wso2is

echo "Changing the ownership of the directory"
sudo chown -R "$USER:$USER" "$USER_HOME/wso2is"
sudo chmod u+w $USER_HOME/wso2is

echo "Downloading the WSO2 Identity Server"
sudo -u $USER wget -P $USER_HOME/wso2is/ https://github.com/wso2/product-is/releases/download/v7.1.0/wso2is-7.1.0.zip

echo "Extracting the WSO2 Identity Server"
sudo -u $USER unzip -q $USER_HOME/wso2is/wso2is-7.1.0.zip -d $EXTRACT_DIR

echo "### Download and extraction completed ###" 
# Clone the artifact repo and copy required files
git clone https://github.com/Lakshan-Banneheke/is-azure-marketplace.git
cd is-azure-marketplace/vm
sudo cp nginx/is.https.conf /etc/nginx/conf.d/is.https.conf
sudo cp is/deployment.toml $USER_HOME/wso2is/wso2is-7.1.0/repository/conf/deployment.toml

# Generate the certificates and copy them to the /etc/ssl/localcerts/ folder
sudo mkdir -p /etc/ssl/localcerts
sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/localcerts/is_public.key -out /etc/ssl/localcerts/is_public.crt -days 365 -nodes -subj "/C=US/ST=California/L=Santa Clara/O=WSO2/OU=IAM Department/CN=is.wso2"

# Generate the keystore with the localhost SAN and import the cert to the trustore
sudo -u $USER keytool -genkey -alias wso2carbon -keyalg RSA -keysize 2048 -keystore $USER_HOME/wso2is/wso2is-7.1.0/repository/resources/security/keystore.p12 -storetype PKCS12 -dname "CN=is.wso2, OU=IAM,O=WSO2,L=SantaClara,S=California,C=US" -storepass wso2carbon -keypass wso2carbon -ext SAN=dns:localhost
sudo -u $USER keytool -export -alias wso2carbon -keystore $USER_HOME/wso2is/wso2is-7.1.0/repository/resources/security/keystore.p12 -storetype PKCS12 -file $USER_HOME/wso2is/wso2is-7.1.0/repository/resources/security/pkn.pem -storepass wso2carbon -noprompt
sudo -u $USER keytool -import -alias newcert -file $USER_HOME/wso2is/wso2is-7.1.0/repository/resources/security/pkn.pem -keystore $USER_HOME/wso2is/wso2is-7.1.0/repository/resources/security/client-truststore.p12 -storetype PKCS12 -storepass wso2carbon -noprompt

# Reload Nginx
sudo service nginx reload

# Start the Identity Server
echo "Starting the WSO2 Identity Server"
sudo -u $USER bash -c "export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64 && $USER_HOME/wso2is/wso2is-7.1.0/bin/wso2server.sh start"

function is_identity_server_up() {
  local status
  status=$(curl -k -L -s \
    -o /dev/null \
    -w "%{http_code}" \
    --request GET \
    "https://localhost:9443/api/health-check/v1.0/health")
  if [[ "$status" == 200 ]]; then
    return 0
  fi
  return 1
}

while ! is_identity_server_up; do
  echo "Waiting for WSO2 Identity Server to be up..."
  sleep 5
done

echo "WSO2 Identity Server is up and running."