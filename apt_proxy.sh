sudo su -
echo 'Acquire::http::Proxy ' "http://10.40.126.7:3128/";' > /etc/apt/apt.conf.d/proxy.conf
echo 'Acquire::https::Proxy ' "http://10.40.126.7:3128/";' >> /etc/apt/apt.conf.d/proxy.conf
