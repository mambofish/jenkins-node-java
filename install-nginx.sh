# apt packages
sudo apt install openjdk-8-jdk
sudo apt install zip

# nginx
sudo apt-key add nginx_signing.key 
sudo echo 'deb https://nginx.org/packages/mainline/debian/ bionic nginx' >> /etc/apt/sources.list
sudo echo 'deb-src https://nginx.org/packages/mainline/debian/ bionic nginx' >> /etc/apt/sources.list
sudo apt-get update
sudo apt install nginx

# creates a composite certificate for nginx. Usually, certificates are installed in two
# parts, the client certificate (clientcert) and the root and any intermediate certificates
# (cacert). nginx requires these to bundled together.
sudo cat /certs/clientcert.cer /certs/cacert.cer | sudo tee /certs/ssl-bundle.cer

echo -n "Enter the public URL of this server and press [ENTER] "
read SERVER_NAME

sudo tee /etc/nginx/sites-available/default << EOF
server {
    listen 443 ssl http2;
    server_name $SERVER_NAME;
    
    client_max_body_size 10G;
    
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
