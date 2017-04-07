# Rationale. YADDC?

You will wonder, yet another drupal docker container?

And our answer is 'yes', a container for developers. We craft it with love listening to our drupal developers suggestions; since they are the ones who use them everyday.

This container is not intended for production, but it could.

## So, what's this about?

This a drupal-able docker container based on the latest Ubuntu LTS (Long Time Support, ubuntu-16.04) release that pretends to be developer friendly and make easy the task of starting a containerized local development.

You are supposed to run any of the supported drupal versions just by:

* Cloning/Forking this repository
* Either:
  * Copying a drupal source code into a 'src' dir inside project's dir
* Or:
  * Perform a 'composer create-project' to download a fresh copy of drupal's source code
* Start the enviroment

Then, since drupal's code is bind mounted inside the container, you can use your favorite IDE to modify the code from outside and run composer/drush/drupal console within the container if needed.
  
# Requirements

* Install latest [docker-engine](https://docs.docker.com/engine/installation/) and [docker-compose](https://docs.docker.com/compose/install)

# Start a drupal development

* Fork project
* Setup your enviroment variables accordingly:
```
export DOCKER_IMAGE="emergya/automated-ubuntu_16.04-drupal:latest"

export DEVELOPER_USER=$(basename $HOME)
export PROJECT_NAME="my-drupal"
export DRUPAL_DEFAULT_SITENAME="$PROJECT_NAME"
export ENVIRONMENT="dev"
export ENV_VHOST="$ENVIRONMENT-$PROJECT_NAME.example.com"

export PROJECT_DIR="$PWD"           # dir where the fork is placed
export DATA_DIR="$PROJECT_DIR/data" # dir where docker volumes are stored
export SSH_CREDENTIALS_DIR=~/.ssh   # this one is used to share you ssh credentials with the containerized git

sed -i "s|_PROJECT_NAME_.emergyalabs.com|$ENV_VHOST|g" *compose.yml # renames compose service name to use your microservice FQDN
```
* Either setup your own drupal source by:
  * Copying your drupal source code into a 'src' dir in project's dir
  * Installing your drupal's composer depends using the containerized 'composer' binary with this snippet:
```
docker-compose -f dev-compose.yml exec $ENV_VHOST \
  /bin/bash -c 'cd /var/www/html; composer install; chown -R $DEVELOPER_USER:www-data /var/www/html'  
```
* Or download a fresh "drupal-$VERSION" source copy using 'composer create-project' with this snippet:
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

NOTE: if you want a database to be deployed as initial database, you can place it in '$PROJECT_DIR/data/initial.sql'. Note that, because the dump is imported, it must include the 'CREATE DATABASE' and 'USE $database' statements at the begining and while running the container, you will need to set the following enviroment variable in order to render 'settings.php' correctly:
```
export MYSQL_DBNAME="your-db-name"
```

If you are performing a fresh drupal installation (when no 'data/initial.sql' database is provided), you will need to set the correct permissions for the programatically (based on container's environment variables) generated 'settings.php'.
You can do it with this snippet:
```
docker-compose -f $ENVIRONMENT-compose.yml exec $ENV_VHOST /bin/bash --login -c 'chmod 660 ${DRUPAL_ROOT}/sites/*/*settings*php'
```
Once installed, you can revert it (restarting the container will perform a 'fix-permissions.sh' that fixes it):
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

* Where did the 'settings.php' files come from?
  * Settings files are dinamically generated from templates on container startup so you can:
    * Add a generic "$DRUPAL_ROOT/sites/default/default.settings.php.tpl"
    * Add some templates for your different environments in "$DRUPAL_ROOT/sites/*/*tpl-$ENVIRONMENT" like:
      * $DRUPAL_ROOT/sites/default/settings.local.php.tpl-$ENVIRONMENT
    * Modify default container templates at 'assets/var/www/html/*tpl' 
  

# TODO: sort braindumped notes

* Note you are using a monolithic container that encapsulates everything, for running it on production, you might start thinking about a decoupled mysql server that is there just to be developer friendly
  * Container will disable the local mysql service if MYSQL_ config is provided via docker environment :)
  * You can provide an inital drupal db by replacing assets/initial.sql
* In production we should use the produced by a CI pipeline image and use the code is inside; you can change the environment divergence)
  * Copying the src as an asset of the docker image in 'assets/var/www/html' and rebuilding the docker image will result in a monolithic image that includes your complete application and php dependencies (as in Dockerfile we run 'compose install' into '/var/www/html' where src is mounted).ATM dependencies will be synchronized on container startup from 'assets' to '/var/www/html', but source code will not.
* Note you will be adding 'data/' dir where data (docker volumes like /var/lib/mysql) is stored to your docker build context
* We perform any of these task as automated project-tasks by using baids