FROM debian:bookworm

RUN apt-get update && apt-get install -y \ 
    ca-certificates \
    php8.2-fpm \
    wget \
    php8.2-mysql\
    mariadb-client \
    tar\
    curl \
    unzip 


RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

COPY tools/wordpress.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/wordpress.sh

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf


CMD ["wordpress.sh"]