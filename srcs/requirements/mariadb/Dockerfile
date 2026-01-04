FROM debian:bookworm

RUN apt-get update &&  apt-get install -y mariadb-server

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/auto.sh /usr/local/bin/auto.sh
RUN chmod +x /usr/local/bin/auto.sh

CMD ["/usr/local/bin/auto.sh"]