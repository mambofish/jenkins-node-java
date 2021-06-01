# apt packages
sudo apt install openjdk-8-jdk
sudo apt install maven
sudo apt install xmlstarlet
sudo apt install zip
sudo apt install build-essential

# nginx
sudo apt install nginx
sudo cat /certs/clientcert.cer /certs/cacert.cer | sudo tee /certs/ssl-bundle.cer

echo -n "Enter the public URL of this server and press [ENTER]"
read SERVER_NAME

sudo tee /etc/nginx/sites-available/default.conf << EOF
server {
    listen 443 ssl http2;
    server_name $SERVER_NAME;
    
    location / {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://127.0.0.1:8080;
    }
    
    ssl_certificate /certs/ssl-bundle.cer;
    ssl_certificate_key /certs/clientcert.key;
} 
EOF
sudo nginx -t
sudo systemctl restart nginx

# node
sudo apt install npm
sudo npm cache clean -f
sudo npm install -f -g npx 
sudo npm install -g n
sudo n stable
echo "npm and node installed with the following versions"
npm -v
node -v

# git-secret
git clone https://github.com/sobolevn/git-secret.git git-secret
cd git-secret && sudo make build
PREFIX="/usr/local" sudo make install

# jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt install jenkins

# initialise jenkins
echo 'JAVA_ARGS="-Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true"' | sudo tee -a /etc/default/jenkins > /dev/null
sudo cp /var/lib/jenkins/config.xml /var/lib/jenkins/config.xml.bak
sudo xmlstarlet ed -u "hudson/crumbIssuer/excludeClientIPFromCrumb" -v true /var/lib/jenkins/config.xml.bak > /var/lib/jenkins/config.xml
echo "Azure Proxy compatibility has been set up. Restarting Jenkins..."
sudo systemctl restart jenkins
echo Jenkins has been restarted. Use the following credentials to perform the initial set up from the Jenkins web server
echo username: admin
echo password: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# install jenkins plugins
[ ! -d "./jenkins-core-plugins" ] && git clone https://github.com/mambofish/jenkins-core-plugins.git
cd jenkins-core-plugins
git pull
sudo cp *.jpi /var/lib/jenkins/plugins
sudo chown jenkins:jenkins /var/lib/jenkins/plugins/*.jpi
sudo systemctl restart jenkins

# jenkins ssh key
ssh-keygen -f ~/.ssh/jenkins-key -t ed25519 -C "jenkins@$SERVER_NAME"
sudo mkdir -p /var/lib/jenkins/keys
sudo cp ~/.ssh/jenkins-key* /var/lib/jenkins/keys
sudo chown jenkins:jenkins /var/lib/jenkins/keys/*
echo "A public/private keypair has been created to allow Jenkins to connect to code repositories using SSH"
echo "The public part of this key must be installed in the target repositories. It is shown below and can found here /var/lib/jenkins/keys/jenkins-key.pub"
cat /var/lib/jenkins/keys/jenkins-key.pub
