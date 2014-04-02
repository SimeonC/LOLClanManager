./node_modules/bower/bin/bower install --allow-root
mkdir ssl
openssl genrsa 1024 -out ssl/key.pem
openssl req -x509 -subj "/C=NZ/ST=Auckland/L=Auckland/CN=tawmanager.localhost" -new -key ssl/key.pem -out ssl/cert.pem