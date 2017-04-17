![build passing](https://img.shields.io/docker/automated/emergya/automated-ubuntu_16.04-drupal.svg)

# ToC (Table of Contents)

   * [Rationale. YADDC?](#rationale-yaddc)
      * [So, what's this about?](#so-whats-this-about)
   * [Requirements](#requirements)
   * [Start a drupal development](#start-a-drupal-development)
      * [Setup considerations](#setup-considerations)
   * [Build your own custom docker image](#build-your-own-custom-docker-image)
   * [Destroy docker enviroment](#destroy-docker-enviroment)
   * [Container's assets](#assets)
   * [FAQ](#faq)
   * [Contributing](#contributing)
   * [Licence and Authors](#licence-and-authors)
   * [TODO: sort braindumped notes](#todo-sort-braindumped-notes)

# Rationale. YADDC?

You will wonder, yet another drupal docker container?

And our answer is 'yes', a container for developers. We craft it with love listening to our drupal developers suggestions; since they are the ones who use them everyday.

This container is not intended for production, but it could.

## So, what's this about?

This a drupal-able docker container based on the latest Ubuntu LTS release (Long Time Support, ubuntu-16.04) that pretends to be developer friendly and make easy the task of starting a local, containerized development.

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

### Setup considerations

* If you want a database to be deployed as initial database, you can place it in '$PROJECT_DIR/data/initial.sql'.
Note also that, because the dump is programatically imported by container's entrypoint and it does have a predefined $MYSQL_DBNAME, the dump must include the 'CREATE DATABASE' and 'USE $MYSQL_DBNAME' statements at the begining. 
While running the environment, you will also need to set this variable in order to render 'settings.php' correctly:
```
export MYSQL_DBNAME="your-db-name"
```
* If you are performing a fresh drupal installation (when no 'data/initial.sql' database is provided), you will need to set the correct permissions for the programatically (based on container's environment variables) generated 'settings.php'.
You can do it with this snippet:
```
docker-compose -f $ENVIRONMENT-compose.yml exec $ENV_VHOST /bin/bash --login -c 'chmod 660 ${DRUPAL_ROOT}/sites/*/*settings*php'
```
  * Once installed, you can revert it (restarting the container will also perform a [fix-permissions.sh](https://www.drupal.org/project/file_permissions) that fixes it):
```
docker-compose -f $ENVIRONMENT-compose.yml exec $ENV_VHOST /bin/bash --login -c 'chmod 640 ${DRUPAL_ROOT}/sites/*/*settings*php'
```

# Build your own custom docker image

* Modify 'Dockerfile' or include any asset on the 'assets' directory (they will be included in container's root filesystem following the same directories hierarchy)
* Build the image accordingly:
```
## Drupal 7
export DRUPAL_VERSION=7
## Drupal 8
export DRUPAL_VERSION=8

export DRUPAL_ROOT=/var/www/html/web

docker build --build-arg DRUPAL_VERSION=$DRUPAL_VERSION --build-arg DRUPAL_ROOT=$DRUPAL_ROOT -t emergya/ubuntu_16.04-drupal:latest .
```

# Destroy docker enviroment

```
export ENVIRONMENT="dev"
cd $PROJECT_DIR
docker-compose -f $ENVIRONMENT-compose.yml down -v
sudo rm -rf data
```

# Assets

* It inherits [ubuntu_16.04-apache-php-mysql upstream's assets](https://github.com/Emergya/ubuntu_16.04-apache-php-mysql/blob/master/README.md#assets) and overwrites some:
```
assets/
├── bin
│   ├── entrypoint-drupal
│   ├── entrypoint.functions-drupal
│   ├── fix-permissions.sh
│   └── upstream-fix-permissions.sh
├── etc
│   ├── apache2
│   │   └── sites-enabled
│   │       └── 000-default.conf
│   ├── drush
│   │   └── aliases.drushrc.php
│   ├── mysql
│   │   └── my.cnf
│   └── php
│       └── 7.0
│           └── apache2
│               ├── conf.d
│               │   └── 20-xdebug.ini
│               └── php.ini
├── initial.sql
└── var
    └── www
        └── html
            ├── composer.json-drupal-project.tpl
            ├── default.settings.php.tpl
            ├── settings.local.php.tpl-drupal-7
            └── settings.local.php.tpl-drupal-8
```

# FAQ

* Where did the 'settings.php' files come from?
  * Settings files are dinamically generated from templates on container startup so you can:
    * Add a generic "$DRUPAL_ROOT/sites/default/default.settings.php.tpl"
    * Add some templates for your different environments in "$DRUPAL_ROOT/sites/*/*tpl-$ENVIRONMENT" like:
      * $DRUPAL_ROOT/sites/default/settings.local.php.tpl-$ENVIRONMENT
    * Modify default container templates at 'assets/var/www/html/*tpl' 
    
# Contributing

1.  Fork the repository on Github
2.  Create a named feature branch (like `add_component_x`)
3.  Write your changes
4.  Submit a Pull Request using Github

# Licence and Authors

Copyright © 2017 Emergya < http://www.emergya.com >

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    The license text is available at https://www.gnu.org/licenses/agpl-3.0.html

Authors:
* [Andrés Muñoz Vera](https://github.com/pellejador) (<amunoz@emergya.com>)
* [Antonio Rodriguez Robledo](https://github.com/yocreoquesi) (<arodriguez@emergya.com>)
* [Alejandro Romo Astorga](https://github.com/aromo) (<aromo@emergya.com>)
* [Diego Martín Sanchez](https://github.com/dmsgago) (<dmsanchez@emergya.com>)
* [Héctor Fiel Martín](https://github.com/hfiel) (<hfiel@emergya.com>)
* [Roberto C. Morano](https://github.com/rcmorano) (<rcmorano@emergya.com>)

# TODO: sort braindumped notes

* Note you are using a monolithic container that encapsulates everything, for running it on production, you might start thinking about a decoupled mysql server that is there just to be developer friendly
  * Container will disable the local mysql service if MYSQL_ config is provided via docker environment :)
  * You can provide an inital drupal db by replacing assets/initial.sql
* In production we should use the container produced by a CI pipeline image and use the source code included inside of that image; you can change the environment divergence in the entrypoint's defined function _set-environment-divergences_
  * Copying the src as an asset of the docker image in 'assets/var/www/html' and rebuilding the docker image will result in a monolithic image that includes your complete application and php dependencies (as in Dockerfile we run 'compose install' into '/var/www/html' where src is mounted).ATM dependencies will be synchronized on container startup from 'assets' to '/var/www/html', but source code will not.
  * Note that building the image will be adding 'data/' dir to the docker image (where data like docker volumes like /var/lib/mysql) is stored since it's located under the docker build context. And we don't want data to be included in a docker-image.
* We perform many of these task as automated project-tasks by using baids
