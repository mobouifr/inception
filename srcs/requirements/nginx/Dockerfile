FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx && apt-get install openssl

# ARG        CERT_FOLDER CERTIFICATE KEY COUNTRY STATE LOCALITY ORGANIZATION UNIT COMMON_NAME

ENV CERT_FOLDER=/certs \
    CERTIFICATE=/certs/server.crt \
    KEY=/certs/server.key \
    COUNTRY=MA \
    STATE=none \
    LOCALITY=Benguerir \
    ORGANIZATION=1337 \
    UNIT=IT \
    COMMON_NAME=mobouifr.42.fr

RUN mkdir -p ${CERT_FOLDER} && \
    openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
    -out ${CERTIFICATE} \
    -keyout ${KEY} \
    -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${UNIT}/CN=${COMMON_NAME}"

RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

COPY conf/default.conf /etc/nginx/sites-available/default

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]