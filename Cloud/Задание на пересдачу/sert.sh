#!/bin/bash

LASTNAME="liskov"
CN="ITHUBlb-${LASTNAME}"
DAYS=365

mkdir -p ~/certs
cd ~/certs

openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout ${CN}.key \
  -out ${CN}.crt \
  -days ${DAYS} \
  -subj "/C=RU/ST=MS/L=Moscow/O=ITHUB/OU=DevOps/CN=${CN}"

echo "Сертификат и ключ созданы в ~/certs:"
ls -l ${CN}.crt ${CN}.key
