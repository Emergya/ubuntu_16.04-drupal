README is a DRAFT/BRAINDUMP
===========================

Yet!

Rationale
=========

* This a drupal-able docker container based on the latest Ubuntu LTS release (ubuntu-16.04) that pretends to be developer friendly.
This means you can run any of the supported drupal versions just copying a drupal into the 'src'.
  * In drupal-8 you must perform a 'composer install' by running:
```
docker-compose -f dev-compose.yml exec dev-_PROJECT_NAME_.emergyalabs.com /bin/bash -c 'cd /var/www/html; composer install; chown -R $DEVELOPER_USER:www-data /var/www/html'
```
    or copying the src as an asset of the docker image in 'assets/var/www/html' and rebuilding the docker image so the resulting image include your complete application and php dependencies (as in Dockerfile we run 'compose install') that will be synchronized on container startup (in production we should use the produced by a CI pipeline image and use the code is inside; you can change the environment divergence)
```
rsync -Pa src/ assets/var/www/html
```
    * Note you will be adding 'data/' dir; where data (docker volumes like /var/lib/mysql) is stored
    * Note you are using a monolithic container that encapsulates everything, for running it on production, you might start thinking about a decoupled mysql server that is there just to be developer friendly
      * Container will disable the local mysql service if MYSQL_ config is provided via docker environment :)
      * You can provide an inital drupal db by replacing assets/initial.sql

  * It's based on our own ubuntu LAMP image (ubuntu-16.04-apache-php-mysql) so it follows the same standards for the container src layout

We perform any of these task as automated project-tasks by using baids

Start a drupal development
==========================

* Fork project
* Setup your enviroment:
```
export DOCKER_IMAGE="emergya/ubuntu_16.04-drupal:latest"

export DEVELOPER_USER=$(basename $HOME)
export PROJECT_NAME="my-drupal"
export DRUPAL_DEFAULT_SITENAME="$PROJECT_NAME"
export PROJECT_DIR="$PWD"
export DATA_DIR="$PROJECT_DIR/data"
export SSH_CREDENTIALS_DIR=~/.ssh
export ENVIRONMENT="dev"
export ENV_VHOST="$ENVIRONMENT-$PROJECT_NAME.example.com"
sed -i "s|_PROJECT_NAME_.emergyalabs.com|$ENV_VHOST|g" *compose.yml

# [un]comment correspondingly
# Drupal 7
#export DRUPAL_VERSION=7
# Drupal 8
export DRUPAL_VERSION=8

export DRUPAL_ROOT=/var/www/html/web

# generate a random drupal's salt
export DRUPAL_SALT=$(base64 /dev/urandom | dd bs=74 count=1 status=none)
echo "Save \$DRUPAL_SALT for future deploys since db is seeded with it: $DRUPAL_SALT"
```
* Install base drupal using the dockerized 'composer' with this snippet:
```
docker-compose -f $ENVIRONMENT-compose.yml run --rm --entrypoint /bin/bash $ENV_VHOST \
  -c "cp -a /assets/var/www/html/composer.json-drupal-project.tpl /tmp/composer.json; \
      # this is a workaround since 'composer --repository is not working :(
      sed -i 's|_DRUPAL_VERSION_|$DRUPAL_VERSION|g' /tmp/composer.json; \
      cd /tmp; yes | composer create-project drupal-composer/drupal-project:~$DRUPAL_VERSION --stability dev; \
      rsync -a /tmp/drupal-project/ /var/www/html/; \
      chown -R $(id -u):www-data /var/www/html; \
      chmod 770 /var/www/html"
```
* Run the environment:
```
docker-compose -f $ENVIRONMENT-compose.yml up -d
```
  * If you are performing a fresh installation (no database) you will need to setup the correct permissions for settings.php files:
```
docker-compose -f $ENVIRONMENT-compose.yml exec $ENV_VHOST /bin/bash --login -c 'chmod 660 ${DRUPAL_ROOT}/sites/*/*settings*php'
```
    * Once installed, you can revert it (althouth starting the container will perform a 'fix-permissions.sh'):
```
docker-compose -f $ENVIRONMENT-compose.yml exec $ENV_VHOST /bin/bash --login -c 'chmod 640 ${DRUPAL_ROOT}/sites/*/*settings*php'
```

Build your own custom docker image
==================================

```
## Drupal 7
export DRUPAL_VERSION=7
export DRUPAL_ROOT=/var/www/html
## Drupal 8
export DRUPAL_VERSION=8
export DRUPAL_ROOT=/var/www/html/web

docker build --build-arg DRUPAL_VERSION=$DRUPAL_VERSION --build-arg DRUPAL_ROOT=$DRUPAL_ROOT -t emergya/ubuntu_16.04-drupal:latest .
```

# Destroy docker enviroment

export ENVIRONMENT="dev"
cd $PROJECT_DIR
docker-compose -f $ENVIRONMENT-compose.yml down -v
sudo rm -rf data

# FAQ

* Settings are dinamically generated from 'assets/var/www/html/*tpl' so you can:
  * Modify those templates
  * Add some for your different environments in $DRUPAL_ROOT/sites/*/*tpl-$ENVIRONMENT

# Assets
