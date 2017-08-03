FROM ubuntu:16.04

####################################################
RUN apt-get update -y \
&& apt-get install wget -y \
&& apt-get install curl -y \
&& rm -rf /etc/nginx/sites-enabled/default \
&& mkdir /lalamove \
&& apt-get install -y sudo && rm -rf /var/lib/apt/lists/*
####################################################


####################################################
 ###   ####   ###   #  ###
#   #  #     #   #  #  #  #
# ###  ###   #   #  #  ###
#   #  #     #   #  #  # 
 ###   ####   ###   #  #
####################################################

RUN mkdir -p /usr/share/GeoIP
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /usr/share/GeoIP/GeoIP.dat
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > /usr/share/GeoIP/GeoLiteCity.dat

####################################################

####################################################
##    #   ####   #  ##    #   #   #
# #   #  #    #  #  # #   #    # #
#  #  #  #  ###  #  #  #  #     #
#   # #  #    #  #  #   # #    # #
#    ##   ####   #  #    ##   #   #
####################################################

###################
# Install nginx #
###################

#RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
#RUN echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx"  >> /etc/apt/sources.list
#RUN curl http://nginx.org/keys/nginx_signing.key | apt-key add -
#RUN sudo apt-get update
#RUN sudo apt-get install nginx build-essential -y

RUN export RUNLEVEL=1 \
&& sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d \
&& apt-get update \
&& apt-get install software-properties-common python-software-properties -y \
&& add-apt-repository ppa:nginx/stable -y \
&& echo "deb-src http://ppa.launchpad.net/nginx/development/ubuntu xenial main" >> /etc/apt/sources.list \
&& apt-get update \
&& apt-get build-dep nginx -y \
&& cd /opt \
&& mkdir tempnginx \
&& cd tempnginx \
&& apt-get source nginx \
&& dirs=./*/ \
&& cd $(echo $dirs) \
&& cd debian \
&& sed  -i '/\thttp-geoip \\/d' rules \
&& sed -i '0,/with-http_geoip_module=dynamic/ s/with-http_geoip_module=dynamic/with-http_geoip_module/' rules \
&& cd libnginx-mod.conf \
&& sed -i 's/load_module/#load_module/g' mod-http-geoip.conf \
&& cd .. \
&& cd .. \
&& dpkg-buildpackage -uc -b \
&& cd ../ \
&& DEBIAN_FRONTEND=noninteractive dpkg --install nginx-common_1.13.3-0+xenial1_all.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-http-dav-ext_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-http-auth-pam_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-http-echo_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-http-geoip_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-http-image-filter_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-http-subs-filter_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-http-upstream-fair_1.13.3-0+xenial1_amd64.deb \ 
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-http-xslt-filter_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-mail_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install libnginx-mod-stream_1.13.3-0+xenial1_amd64.deb \
&& DEBIAN_FRONTEND=noninteractive dpkg --install nginx-full_1.13.3-0+xenial1_amd64.deb \
&& service nginx stop

###################

###################
# Configure nginx #
###################

COPY nginx_geoip_params              /etc/nginx/geoip_params
COPY nginx_log_format.conf           /etc/nginx/conf.d/10-nginx_log_format.conf
COPY nginx_real_ip.conf              /etc/nginx/conf.d/10-nginx_real_ip.conf
RUN rm -rf /etc/nginx/conf.d/default.conf

#######################
# nginx vhosts config #
#######################

COPY vhost.conf /etc/nginx/vhost.conf
COPY _main-location-ip-rules.conf /etc/nginx/conf/_main-location-ip-rules.conf
COPY _more.conf /etc/nginx/conf/_more.conf
COPY _http-basic-auth.conf /etc/nginx/conf/_http-basic-auth.conf
COPY _htpasswd /etc/nginx/conf/_htpasswd

COPY nginx.conf                      /etc/nginx/nginx.conf
COPY entry.sh /entry.sh

RUN rm -rf /etc/nginx/sites-available && rm -rf /etc/nginx/sites-enabled
####################################################
####    #   #   ####
#   #   #   #   #   #
####    #####   ####
#       #   #   #
#       #   #   #
####################################################

########################
# Install PHP packages #
########################

RUN sudo apt-get update
RUN sudo apt-get install python-software-properties -y
RUN sudo apt-get install software-properties-common -y

RUN apt-get update
RUN apt-get install -y php-fpm \
&& apt-get install -y libcurl4-openssl-dev \
&& apt-get install -y pkg-config \
&& apt-get install -y libssl-dev \
&& apt-get install -y libsslcommon2-dev \
&& apt-get install -y libpcre3-dev \
&& apt-get install -y php-cli \
&& apt-get install -y php-cgi \
&& apt-get install -y psmisc \
&& apt-get install -y spawn-fcgi \
&& apt-get install -y pkg-php-tools \
&& apt-get install -y php-pear
 


RUN apt-get update
RUN mkdir -p /var/log/php-ypm/

#ref: http://www.bictor.com/2015/02/15/installing-mongodb-yor-php-in-ubuntu-14-04/
#ref: https://github.com/mongodb/mongo-php-driver/issues/138
#ref: http://stackoverflow.com/questions/22555561/error-building-yatal-error-pcre-h-no-such-yile-or-directory
#ref: https://docs.mongodb.com/ecosystem/drivers/php/


####################################################
#    #   ####   #    #   ####    ####
##  ##  #    #  ##   #  #       #    #
# ## #  #    #  # #  #  #  ###  #    #
#  # #  #    #  #  # #  #    #  #    #
#    #   ####   #   ##   ####    ####
####################################################

##############################################
# Install MongoDB PHP driver on Ubuntu 14.04 #
##############################################

# Assuming you already have Nginx and PHP installed and want to add MongoDB support.

# Install pre-requisites
RUN apt-get install -y php-common
RUN apt-get install -y php-cgi
RUN apt-get install -y php-curl
RUN apt-get install -y php-json
RUN apt-get install -y php-mcrypt
RUN apt-get install -y php-mysql
RUN apt-get install -y php-sqlite3
RUN apt-get install -y php-dev
RUN apt-get install -y php-apcu

RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
RUN sudo apt-get update
RUN sudo apt-get install -y php-mongodb
RUN echo "extension=mongo.so" >> /etc/php/7.0/fpm/php.ini

RUN apt-get install -y mongodb

####################################################
RUN adduser --disabled-password --gecos '' r \
&& adduser r sudo \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

####################################################
####################################################
RUN mkdir -p /usr/share/GeoIP
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /usr/share/GeoIP/GeoIP.dat
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > /usr/share/GeoIP/GeoLiteCity.dat
####################################################

COPY supervisor.conf /opt/docker/etc/supervisor.conf

RUN apt-get update -y
RUN apt-get install -y git curl python3.4 python-pip supervisor


####################################################
# added s3fs command
RUN sudo apt-get install -y build-essential
RUN apt-get install -y git
RUN apt-get install -y libfuse-dev
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y libxml2-dev
RUN apt-get install -y mime-support
RUN apt-get install -y automake libtool
RUN apt-get install -y pkg-config #libssl-dev # See (*3)
RUN sudo apt-get install -q -y s3fs


RUN sudo apt-get install -y -q nodejs

RUN sudo npm install --g gulp
RUN sudo npm install gulp laravel-elixir
RUN sudo npm uninstall npm -g

####################################################
RUN sudo apt-get install vim -y
RUN sed -i 's/\/run\/php\/php7\.0-fpm\.sock/127\.0\.0\.1:9000/g' /etc/php/7.0/fpm/pool.d/www.conf
####################################################
COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
COPY before-entry.sh /before-entry.sh
RUN chmod +x /before-entry.sh
####################################################
#USER docker
EXPOSE 80 443
ENTRYPOINT ["/entry.sh"]
CMD ["/entry.sh"]
