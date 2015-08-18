FROM marvambass/nginx-ssl-php
# derived from marvambass/piwik
MAINTAINER Markus Kosmal <code@m-ko-x.de>

ENV DH_SIZE 2048

RUN export TERM=xterm

RUN apt-get update; apt-get install -yqq \
    mysql-client \
    php5-mysql \
    php5-gd \
    php5-geoip \
    php-apc \
    php5-dev \
    libgeoip-dev \
    curl \
    nano

# clean http directory
RUN rm -rf /usr/share/nginx/html/*

# install nginx piwik config
ADD conf/nginx-piwik.conf /etc/nginx/conf.d/nginx-piwik.conf

# download piwik
RUN curl -O "http://builds.piwik.org/piwik.zip"

# unarchive piwik
RUN unzip piwik.zip

# add piwik config
ADD conf/config.ini.php /piwik/config/config.ini.php

# add geo db
ADD db/GeoIPCity.dat /piwik/misc/
RUN chown www-data:www-data /piwik/misc/GeoIPCity.dat

# add startup.sh
ADD script/bootstrap.sh /opt/startup-piwik.sh
RUN chmod a+x /opt/startup-piwik.sh

ENV PIWIK_TRUSTED_HOST_ACTIVE 0
ENV PIWIK_TRUSTED_HOST localhost

RUN sed -i 's/{{PIWIK_TRUSTED_HOST_MARKER}}/${PIWIK_TRUSTED_HOST}/g' /piwik/config/config.ini.php
RUN sed -i 's/{{PIWIK_TRUSTED_HOST_ACTIVE_MARKER}}/${PIWIK_TRUSTED_HOST_ACTIVE}/g' /piwik/config/config.ini.php

# add '/opt/startup-piwik.sh' to entrypoint.sh
RUN sed -i 's/# exec CMD/# exec CMD\n\/opt\/startup-piwik.sh/g' /opt/entrypoint.sh

# add missing always_populate_raw_post_data = -1 to php.ini (bug #8, piwik bug #6468)
RUN sed -i 's/;always_populate_raw_post_data/always_populate_raw_post_data/g' /etc/php5/fpm/php.ini