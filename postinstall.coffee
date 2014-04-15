bower = require 'bower'
bower.install()
# path = require 'path'
# fs = require 'fs'
# fs.mkdir path.resolve 'ssl'


# openssl genrsa 1024 -out ssl/key.pem
# openssl req -x509 -subj "/C=NZ/ST=Auckland/L=Auckland/CN=tawmanager.localhost" -new -key ssl/key.pem -out ssl/cert.pem