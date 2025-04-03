#!/bin/bash

function print_usage {
    echo -e "Usage: $0 [options]\n"
    echo "[Deployment Configurations]"
    echo "--deployment-toml-uri                            - URI of the deployment.toml file [mandatory]"
    echo "--populate-db-script-uri                         - URI of the database population script [mandatory]"
    echo "--jdbc-driver-uri                                - URI of the JDBC driver [mandatory]"
    echo "--user                                           - Admin user [mandatory]"
    echo ""
    echo "[Database Configurations]"
    echo "--enable-setup-db                                - Enable database setup (true/false) [mandatory]"
    echo "--sql-server-name                                - Name of the SQL Server instance [mandatory]"
    echo "--sql-server-admin-username                      - SQL Server admin username [mandatory]"
    echo "--sql-server-admin-password                      - SQL Server admin password [mandatory]"
    echo ""
    echo "[Clustering Configurations]"
    echo "--private-ip-node-local                              - Private IP of the first node [mandatory]"
    echo "--private-ip-node-peer                              - Private IP of the second node [mandatory]"
    echo;
    echo "e.g. $0 --deployment-toml-uri=/resources/deployment.toml --sql-server-name=my-sql-server"
    exit 1;
}

# Parse arguments
for arg in "$@"
do
    case ${arg} in
        --deployment-toml-uri=*)
        DEPLOYMENT_TOML_URI="${arg#*=}"
        shift
        ;;
        --populate-db-script-uri=*)
        POPULATE_DB_SCRIPT_URI="${arg#*=}"
        shift
        ;;
        --jdbc-driver-uri=*)
        JDBC_DRIVER_URI="${arg#*=}"
        shift
        ;;
        --user=*)
        USER="${arg#*=}"
        shift
        ;;
        --enable-setup-db=*)
        ENABLE_SETUP_DB="${arg#*=}"
        shift
        ;;
        --sql-server-name=*)
        SQL_SERVER_NAME="${arg#*=}"
        shift
        ;;
        --sql-server-admin-username=*)
        SQL_SERVER_ADMIN_USERNAME="${arg#*=}"
        shift
        ;;
        --sql-server-admin-password=*)
        SQL_SERVER_ADMIN_PASSWORD="${arg#*=}"
        shift
        ;;
        --private-ip-node-local=*)
        PRIVATE_IP_NODE_LOCAL="${arg#*=}"
        shift
        ;;
        --private-ip-node-peer=*)
        PRIVATE_IP_NODE_PEER="${arg#*=}"
        shift
        ;;
        *)
        print_usage
        ;;
    esac
done

# Validate required parameters
if [[ -z "$DEPLOYMENT_TOML_URI" || -z "$POPULATE_DB_SCRIPT_URI" || -z "$JDBC_DRIVER_URI" || -z "$USER" || -z "$ENABLE_SETUP_DB" || -z "$SQL_SERVER_NAME" || -z "$SQL_SERVER_ADMIN_USERNAME" || -z "$SQL_SERVER_ADMIN_PASSWORD" || -z "$PRIVATE_IP_NODE_LOCAL" || -z "$PRIVATE_IP_NODE_PEER" ]]; then
    echo "Error: All mandatory parameters must be provided."
    print_usage
fi


# Print all parameters
echo "DEPLOYMENT_TOML_URI: $DEPLOYMENT_TOML_URI"
echo "POPULATE_DB_SCRIPT_URI: $POPULATE_DB_SCRIPT_URI"
echo "JDBC_DRIVER_URI: $JDBC_DRIVER_URI"
echo "USER: $USER"
echo "ENABLE_SETUP_DB: $ENABLE_SETUP_DB"
echo "SQL_SERVER_NAME: $SQL_SERVER_NAME"
echo "SQL_SERVER_ADMIN_USERNAME: $SQL_SERVER_ADMIN_USERNAME"
echo "SQL_SERVER_ADMIN_PASSWORD: $SQL_SERVER_ADMIN_PASSWORD"
echo "PRIVATE_IP_NODE_LOCAL: $PRIVATE_IP_NODE_LOCAL"
echo "PRIVATE_IP_NODE_PEER: $PRIVATE_IP_NODE_PEER"

USER_HOME=/home/${USER}
IS_EXTRACT_DIR="${USER_HOME}/wso2is"
IS_PACK_VERSION="7.1.0"
IS_HOME="${IS_EXTRACT_DIR}/wso2is-${IS_PACK_VERSION}"

IS_DB_SCRIPTS_PATH="${IS_HOME}/dbscripts"

function update_and_install_packages() {

  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install unzip -y
  sudo apt-get install wget -y
}

function install_java() {

  sudo NEEDRESTART_MODE=a apt install -y wget apt-transport-https
  sudo mkdir -p /etc/apt/keyrings
  wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
  echo deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main | sudo tee /etc/apt/sources.list.d/adoptium.list
  sudo NEEDRESTART_MODE=a apt-get update
  sudo NEEDRESTART_MODE=a apt install -y temurin-17-jdk=17.0.14.0.0+7-1
  echo \"JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64\" | sudo tee -a /etc/environment
  echo \"JAVA_HOME_17_X64=/usr/lib/jvm/temurin-17-jdk-amd64\" | sudo tee -a /etc/environment
}

function configure_identity_server() {

  # Copy required files
  # TODO DB username and passwords? Need to get SED the DB credentials and the admin credentials to the toml
  # TODO Differentiate between the manager and worker nodes in TOML clustering conf
  # TODO Add the private VM IPs to the toml file
  echo "Configuring the WSO2 Identity Server" 
  sudo cp "$DEPLOYMENT_TOML_URI" "${IS_HOME}/repository/conf/deployment.toml"
  sudo cp "$JDBC_DRIVER_URI" "${IS_HOME}/repository/components/lib/"
}

function install_identity_server() {

  echo "##### Installing WSO2 Identity Server #####"
  echo "Creating the directory"
  sudo -u "$USER" mkdir "$IS_EXTRACT_DIR"

  echo "Changing the ownership of the directory"
  sudo chown -R "$USER:$USER" "$IS_EXTRACT_DIR"
  sudo chmod u+w "$IS_EXTRACT_DIR"

  echo "Downloading the WSO2 Identity Server"
  sudo -u "$USER" wget -P "$IS_EXTRACT_DIR"/ https://github.com/wso2/product-is/releases/download/v${IS_PACK_VERSION}/wso2is-${IS_PACK_VERSION}.zip

  sudo -u "$USER" unzip -q "${IS_HOME}.zip" -d "$IS_EXTRACT_DIR"
  configure_identity_server
}

function install_sqlcmd() {

  curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
  sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/prod.list)" -y
  sudo apt-get update -y
  sudo apt-get install sqlcmd -y
}

function setup_databases() {

  ###### TODO: Execute this only if this is the manager node
  echo "### Setting up the databases ###"
  install_sqlcmd
  sudo -u "$USER" bash "$POPULATE_DB_SCRIPT_URI" "$IS_DB_SCRIPTS_PATH" "$SQL_SERVER_NAME" "$SQL_SERVER_ADMIN_USERNAME" "$SQL_SERVER_ADMIN_PASSWORD"
  echo "### Database setup completed ###"
}

function start_identity_server() {

  echo "### Starting the WSO2 Identity Server ###"
  sudo -u "$USER" bash -c "export JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64 && ${IS_HOME}/bin/wso2server.sh start"

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

  echo "##### WSO2 Identity Server is up and running. #####"
}

# update_and_install_packages

# install_java

# install_identity_server

# if [[ "$ENABLE_SETUP_DB" == "true" ]]; then
#   setup_databases
# fi

# start_identity_server
