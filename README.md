# Rationale. YADDC?

You will wonder, yet another drupal docker container?

And our answer is 'yes'; because we craft our own docker containers with love listening to our drupal developers since they are the ones who use them everyday.

## So, what's this about?

This a drupal-able docker container based on the latest Ubuntu LTS (Long Time Support) release (ubuntu-16.04) that pretends to be developer friendly and need nothing but [docker-composer](https://docs.docker.com/compose/) to start a containerized local development and use your favorite IDE in your own desktop to modify the code.

This means you are supposed to run any of the supported drupal versions just by:

* Cloning/Forking this repository
* Either:
  * Copying a drupal source code into a 'src' in project's dir
* Or:
  * Perform a 'composer create-project' to download drupal's source code
  
# Requirements

* Install latest [docker-engine](https://docs.docker.com/engine/installation/) and [docker-compose](https://docs.docker.com/compose/install)

# Start a drupal development

* Fork project
* Setup your enviroment variables accordingly:
```
export DOCKER_IMAGE="emergya/automated-ubuntu_16.04-drupal:latest"

export DEVELOPER_USER=$(basename $HOME)
export PROJECT_NAME="my-drupal"
export PROJECT_DIR="$PWD"
export DATA_DIR="$PROJECT_DIR/data"
export SSH_CREDENTIALS_DIR=~/.ssh
export ENVIRONMENT="dev"
export ENV_VHOST="$ENVIRONMENT-$PROJECT_NAME.example.com"

export DRUPAL_DEFAULT_SITENAME="$PROJECT_NAME"

sed -i "s|_PROJECT_NAME_.emergyalabs.com|$ENV_VHOST|g" *compose.yml
```
* Setup drupal source
  * Either:
    * Copy your drupal source code into a 'src' dir in project's dir
    * Install your drupal's composer depends using the containerized 'composer' binary with this snippet:
```
docker-compose -f dev-compose.yml exec $ENV_VHOST \
  /bin/bash -c 'cd /var/www/html; composer install; chown -R $DEVELOPER_USER:www-data /var/www/html'  
```
   * If you want a database to be deployed as initial database, you can place it in '$PROJECT_DIR/data/initial.sql'. Note that it must include the 'CREATE DATABASE' and 'USE $database' statements at the begining and that you must set the following enviroment variable also:
```
export MYSQL_DBNAME="your-db-name"
```
  * Or:
    * Download a fresh "drupal-$VERSION" source copy using 'composer create-project' with this snippet:
```
# [un]comment correspondingly
# Drupal 7
#export DRUPAL_VERSION=7
# Drupal 8
export DRUPAL_VERSION=8

export DRUPAL_ROOT=/var/www/html/web

docker-compose -f $ENVIRONMENT-compose.yml run --rm --entrypoint /bin/bash $ENV_VHOST \
  -c "cp -a /assets/var/www/html/composer.json-drupal-project.tpl /tmp/composer.json; \
      # this is a workaround since 'composer --repository is not working :(
      sed -i 's|_DRUPAL_VERSION_|$DRUPAL_VERSION|g' /tmp/composer.json; \
      cd /tmp; yes | composer create-project drupal-composer/drupal-project:~$DRUPAL_VERSION --stability dev; \
      rsync -a /tmp/drupal-project/ /var/www/html/; \
      chown -R $(id -u):www-data /var/www/html; \
      chmod 770 /var/www/html"
```
* Generate a random drupal's salt (and save it, since database will be seeded with it)
```
export DRUPAL_SALT=$(base64 /dev/urandom | dd bs=74 count=1 status=none)
echo "Save \$DRUPAL_SALT for future deploys since db is seeded with it: $DRUPAL_SALT"
```
* Run the environment:
```
docker-compose -f $ENVIRONMENT-compose.yml up -d
```

If you are performing a fresh installation (no database) you will need to setup the correct permissions for the automatically generated 'settings.php' files in order the installer to work:
```
docker-compose -f $ENVIRONMENT-compose.yml exec $ENV_VHOST /bin/bash --login -c 'chmod 660 ${DRUPAL_ROOT}/sites/*/*settings*php'
```
* Once installed, you can revert it (althouth restarting the container will perform a 'fix-permissions.sh' that fixes it):
```
docker-compose -f $ENVIRONMENT-compose.yml exec $ENV_VHOST /bin/bash --login -c 'chmod 640 ${DRUPAL_ROOT}/sites/*/*settings*php'
```

# Build your own custom docker image

```
## Drupal 7
export DRUPAL_VERSION=7
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

# Dummy notes



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
