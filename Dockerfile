FROM alpine:3.6

ENV PYTHON_VERSION=2.7.13-r1
ENV PY_PIP_VERSION=9.0.1-r1
ENV SUPERVISOR_VERSION=3.3.1

####################################################
####    ###    ####  #   ####
#   #  #   #  #      #  #
####   #####   ###   #  #
#   #  #   #      #  #  # 
####   #   #  ####   #   ####
####################################################

RUN echo "ipv6" >> /etc/modules
RUN apk update && \
    apk upgrade && \
    apk add sudo && \
    apk --no-cache add --update alpine-sdk && \
    adduser -D -g '' r && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /run/php && \
    apk --no-cache add vim && \
    apk --no-cache add netcat-openbsd && \
    apk --no-cache add ca-certificates wget && \
    apk --no-cache add bash bash-doc bash-completion && \
    apk --no-cache add openssl && \
    apk --no-cache add openrc && \
    rm -rf /var/cache/apk/*

RUN addgroup -g 10001 -S www-data \
 && adduser -u 10001 -D -S -G www-data www-data

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
COPY before-entry.sh /before-entry.sh
RUN chmod +x /before-entry.sh

####################################################
 ###   #####   ###   #  ####
#   #  #      #   #  #  #   #
# ###  ###    #   #  #  ####
#   #  #      #   #  #  # 
 ###   #####   ###   #  #
####################################################

RUN mkdir -p /usr/share/GeoIP
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /usr/share/GeoIP/GeoIP.dat
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > /usr/share/GeoIP/GeoLiteCity.dat

####################################################
##    #   ####   #  ##    #   #   #
# #   #  #    #  #  # #   #    # #
#  #  #  #  ###  #  #  #  #     #
#   # #  #    #  #  #   # #    # #
#    ##   ####   #  #    ##   #   #
####################################################

RUN echo "@latest-stable http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories
RUN apk update && \
    apk add nginx@latest-stable nginx-mod-http-geoip@latest-stable && \
    rm -rf /var/cache/apk/*

COPY nginx_geoip_params              /etc/nginx/geoip_params
COPY nginx_log_format.conf           /etc/nginx/conf.d/10-nginx_log_format.conf
COPY nginx_real_ip.conf              /etc/nginx/conf.d/10-nginx_real_ip.conf
RUN rm -rf /etc/nginx/conf.d/default.conf

COPY vhost.conf /etc/nginx/vhost.conf
COPY _main-location-ip-rules.conf /etc/nginx/conf/_main-location-ip-rules.conf
COPY _more.conf /etc/nginx/conf/_more.conf
COPY _http-basic-auth.conf /etc/nginx/conf/_http-basic-auth.conf
COPY _htpasswd /etc/nginx/conf/_htpasswd

COPY nginx.conf                      /etc/nginx/nginx.conf
COPY entry.sh /entry.sh
COPY phpcheck.sh /opt/docker/phpcheck.sh
RUN rm -rf /etc/nginx/sites-available && rm -rf /etc/nginx/sites-enabled

###################################################
#####  #####   ####
#        #    #
###      #    #
#        #    #
#####    #     ####
###################################################

COPY supervisor.conf /opt/docker/etc/supervisor.conf

RUN apk update && \
    apk upgrade && \
    apk --no-cache add -u python2=$PYTHON_VERSION py-pip=$PY_PIP_VERSION && \
    apk add --no-cache autoconf && \
    pip install supervisor==$SUPERVISOR_VERSION && \
    rm -rf /var/cache/apk/*


###################################################
####   #   #  ####
#   #  #   #  #   #
####   #####  ####
#      #   #  #
#      #   #  #
###################################################

# DONT INSTALL MYSQLND

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/3.6/main' >> /etc/apk/repositories && \
    apk --update add \
        php7=7.1.9-r0 \
        php7-bcmath \
        php7-dom \
        php7-ctype \
        php7-curl \
        php7-fileinfo \
        php7-fpm \
        php7-gd \
        php7-gmp \
        php7-iconv \
        php7-imagick \
        php7-intl \
        php7-json \
        php7-mbstring \
        php7-mcrypt \
	php7-mysqli \
	php7-opcache \
        php7-openssl \
	php7-redis \
        php7-pdo \
        php7-pdo_mysql \
        php7-pdo_pgsql \
        php7-pdo_sqlite \
        php7-phar \
        php7-posix \
        php7-session \
        php7-soap \
        php7-xml \
        php7-xmlreader \
        php7-xmlwriter \
        php7-zip \
        php7-dev \
        php7-pear \
        php7-simplexml \
        php7-tokenizer \
    && apk add --no-cache pcre-dev@latest-stable && \
    apk add --no-cache --virtual .mongodb-ext-build-deps openssl-dev && \
    pecl install mongodb && \
    pecl clear-cache && \
    apk del .mongodb-ext-build-deps && \
    rm -rf /var/cache/apk/*

RUN set -x \
	&& addgroup -g 82 -S application \
	&& adduser -u 82 -D -S -G application application

RUN sed -i "s/nobody/application/g" /etc/php7/php-fpm.d/www.conf

RUN sed -i "s/pm.max_children = 5/pm.max_children = 64/g" /etc/php7/php-fpm.d/www.conf
RUN sed -i "s/pm.start_servers = 2/pm.start_servers = 12/g" /etc/php7/php-fpm.d/www.conf
RUN sed -i "s/pm.min_spare_servers = 1/pm.min_spare_servers = 8/g" /etc/php7/php-fpm.d/www.conf
RUN sed -i "s/pm.max_spare_servers = 3/pm.max_spare_servers = 16/g" /etc/php7/php-fpm.d/www.conf
RUN sed -i "s/;pm.max_requests/pm.max_requests/g" /etc/php7/php-fpm.d/www.conf
RUN sed -i "s/;pm.status_path = \/status/pm.status_path = \/fpm_status/g" /etc/php7/php-fpm.d/www.conf


COPY 00_mongo.ini /etc/php7/conf.d/

### Add Composer 

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN php -r "unlink('composer-setup.php');"

###################################################
#USER docker
EXPOSE 80 443
RUN dos2unix /entry.sh
CMD ["/entry.sh"]
