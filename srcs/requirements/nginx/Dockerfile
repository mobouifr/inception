FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx && apt-get install openssl

ARG COUNTRY STATE LOCALITY ORGANIZATION UNIT COMMON_NAME
RUN mkdir -p /etc/ssl/certs /etc/ssl/private

RUN openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
	-out /etc/ssl/certs/server.crt \
	-keyout /etc/ssl/private/server.key \
	-subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCALITY}/O=${ORGANIZATION}/OU=${UNIT}/CN=${COMMON_NAME}"

RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

COPY conf/default.conf /etc/nginx/sites-available/default

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]