#!/bin/bash
set -e

error='\033[37m\033[41m'
success='\033[30m\033[42m'
warning='\033[30m\033[43m'
info='\033[37m\033[44m'
blue='\033[34m'
yellow='\033[33m'
green='\033[32m'
clr='\033[0m'

function spinner() {
  chars="◐◓◑◒"

  while :; do
    for ((i = 0; i < ${#chars}; i++)); do
      sleep 0.5
      echo -en "$1 ${chars:$i:1}" "\r"
    done
  done
}

APP_NAME="numbernine"

if [ -n "$1" ]; then
  APP_NAME=$1
fi

tput civis

echo ''
echo -e "$success                                                                                                                        $clr"
echo -e "$success NumberNine installation in progress                                                                                    $clr"
echo -e "$success                                                                                                                        $clr"
echo ''
echo "Creating new project in ./$APP_NAME directory."
spinner 'Please wait while preparing your project...' &
PID=$!

{
  mkdir -p /srv/app/$APP_NAME

  if [ -z "$(ls -A /srv/app/$APP_NAME/)" ]; then
    cd /srv/files/
    cp -R . /srv/app/$APP_NAME/

    cd /srv/app/$APP_NAME/

    sed -i "s@APP_NAME=numbernine@APP_NAME=$APP_NAME@g" .env.local
    sed -i "s@localhost@$APP_NAME.localhost@g" ./docker/nginx/conf.d/default.conf
    sed -i "s@localhost@$APP_NAME.localhost@g" docker-compose.yml
    sed -i "s@- ./@- $HOST_PWD/$APP_NAME/@g" docker-compose.yml

    mkdir -p docker/nginx/cert
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
      -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$APP_NAME.localhost" \
      -keyout ./docker/nginx/cert/$APP_NAME.localhost.key \
      -out ./docker/nginx/cert/$APP_NAME.localhost.crt
  fi

  chown -R appuser:appgroup /srv/app/$APP_NAME
  cd /srv/app/$APP_NAME/

  docker-compose up -d
  sudo -u appuser sed -i "s@- $HOST_PWD/$APP_NAME/@- ./@g" docker-compose.yml
  sudo -u appuser rm -rf var/cache && sudo -u appuser mkdir -pm 0755 var/cache
  docker-compose exec php php -r "set_time_limit(30); for(;;) { if(@fsockopen('mysql:'.(3306))) { break; } }"
  docker-compose exec php bin/console doctrine:database:drop --if-exists --force
  docker-compose exec php bin/console doctrine:database:create --if-not-exists
  docker-compose exec php bin/console doctrine:migrations:diff --no-interaction
  docker-compose exec php bin/console doctrine:migrations:migrate --no-interaction
  docker-compose exec php bin/console doctrine:fixtures:load --no-interaction
  docker-compose exec php bin/console cache:clear
} &> /dev/null

kill $PID
tput cnorm

echo ''
echo ''
echo -e "$info                                                                                                                        $clr"
echo -e "$info What's next?                                                                                                           $clr"
echo -e "$info                                                                                                                        $clr"
echo ''
echo -e "  * ${blue}Read$clr the documentation at ${yellow}https://numberninecms.github.io/$clr"
echo ''
echo -e "  * ${blue}Create$clr an admin user ${yellow}docker-compose exec php bin/console numbernine:user:create --admin$clr"
echo ''
echo -e "  * ${blue}Go$clr to ${yellow}https://$APP_NAME.localhost/admin ${clr}and login with your newly created user"
echo ''
echo -e "  * ${blue}Go$clr to ${yellow}http://localhost:8010/ ${clr}to check mails sent by the app"
