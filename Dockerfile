FROM emergya/ubuntu_16.04-apache-php-mysql:201704232319-95dd796

ENV BUILD_TIMESTAMP 201704051337
ENV DRUSH_VERSION 8.1.10
ENV DRUPAL_VERSION 8
ENV DRUPAL_ROOT /var/www/html/web
ARG DRUPAL_VERSION=8
ARG DRUPAL_ROOT=/var/www/html/web

## Install Drush.
RUN composer global require drush/drush:$DRUSH_VERSION && \
    mv $HOME/.composer /usr/local/share/composer && \
    ln -s /usr/local/share/composer/vendor/drush/drush/drush /usr/local/bin/drush

## Install drupal console
RUN curl https://drupalconsole.com/installer -L -o /usr/local/bin/drupal && \
    chmod +x /usr/local/bin/drupal

## make composer to cache a drupal-$DRUPAL_VERSION in user cache
ADD assets/var/www/html/composer.json-drupal-project.tpl /assets/var/www/html/composer.json-drupal-project.tpl
RUN /bin/bash --login -c '\
      cp -a /assets/var/www/html/composer.json-drupal-project.tpl /tmp/composer.json; \
      # this is a workaround since 'composer --repository is not working :(
      sed -i "s|_DRUPAL_VERSION_|$DRUPAL_VERSION|g" /tmp/composer.json; \
      cd /tmp; yes | composer create-project drupal-composer/drupal-project:~$DRUPAL_VERSION --stability dev; \
      rm -rf /tmp/drupal-project /tmp/composer.json'


## Install Drupal dependencies with composer
ADD assets/var/www/html /assets/var/www/html
RUN /bin/bash -c 'if [ -e /assets/var/www/html/composer.json ]; then \
                    mv /var/www/html /var/www/html.dist; \
                    ln -s /assets/var/www/html /var/www/html; \
                    mv /etc/php/7.0/cli/conf.d/20-xdebug.ini /tmp/; \
                    composer install; \
                    mv /tmp/20-xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini; \
                    chown -R www-data: /var/www/html/; \
                    rm -f /var/www/html; mkdir /var/www/html; \
                  else \
                    exit 0; \
                  fi'

ADD assets /assets

ENTRYPOINT ["/assets/bin/entrypoint-drupal"]
