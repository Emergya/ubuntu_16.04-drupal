#!/bin/bash

set -x

if [ ! -z "$SUDO_USER" ] && [ ! -z "$DEVELOPER_USER" ] && [ "$DEVELOPER_USER" != "$SUDO_USER" ]
then
  sudo -E $0
  exit 0
fi

if [ "$(id -un $DEVELOPER_USER)" == "root" ]
then
  DRUPAL_USER="root"
else
  DRUPAL_USER="$DEVELOPER_USER"
fi

# if no DRUPAL_VERSION is specified, try to guess DRUPAL_ROOT if not specified
if [ -z "$DRUPAL_VERSION" ]
then
  case $DRUPAL_ROOT in
    "/var/www/html/web")
      export DRUPAL_VERSION="8"
    ;;
    "/var/www/html")
      export DRUPAL_VERSION="7"
    ;;
    *) 
      if [ ! -z "$DRUPAL_ROOT" ]
      then
        echo $DRUPAL_ROOT | grep -q web$
        if [ $? -eq 0 ]
        then
          export DRUPAL_VERSION="8"
        else
          export DRUPAL_VERSION="7"
        fi
      else

        if [ -e "/var/www/html/web" ]
        then
          export DRUPAL_VERSION="8"
        else
          export DRUPAL_VERSION="7"
        fi
      fi
     ;;
  esac
fi

# if DRUPAL_VERSION specified, set DRUPAL_ROOT if not already set/specified
case $DRUPAL_VERSION in
    7)
      if [ -z "$DRUPAL_ROOT" ]
      then
        export DRUPAL_ROOT="/var/www/html"
      else
        export DRUPAL_ROOT
      fi
    ;;
    8)
      if [ -z "$DRUPAL_ROOT" ]
      then
        export DRUPAL_ROOT="/var/www/html/web"
      else
        export DRUPAL_ROOT
      fi
  ;;
esac

# set perms for FTP users (in case we add FTP features) to reach public dir \
PASS_THRU_PATHS='/var/www/html/web /var/www/html/web/sites /var/www/html/web/sites/default /var/www/html/web/sites/default/files'

( /assets/bin/upstream-fix-permissions.sh --drupal_path=$DRUPAL_ROOT --drupal_user=$DRUPAL_USER --httpd_group=www-data && \
  /bin/bash -c " \
  chown ${DEVELOPER_USER}:www-data ${DRUPAL_ROOT}/sites/*/{files,private}; \
  chmod 775 ${DRUPAL_ROOT}/sites/*/{files,private}; \
  chown ${DEVELOPER_USER}:www-data /var/www/html; \
for dir in $PASS_THRU_PATHS; \
do \
 chmod 775 \$dir; \
done" ) &
