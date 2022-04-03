#!/bin/bash
error='\033[37m\033[41m'
success='\033[30m\033[42m'
warning='\033[30m\033[43m'
info='\033[37m\033[44m'
blue='\033[34m'
yellow='\033[33m'
green='\033[32m'
clr='\033[0m'
verbose=0

parse_options() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -v|--verbose) verbose=1 ;;
        esac
        shift
    done
}

spinner() {
  chars="◐◓◑◒"

  while :; do
    for ((i = 0; i < ${#chars}; i++)); do
      sleep 0.5
      echo -en "$1 ${chars:$i:1}" "\r"
    done
  done
}

execute() {
    if [ $verbose -eq 1 ] ; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

set_app_name() {
  APP_NAME="numbernine"

  echo "$1" | grep -Pq '^(?!-+)[\w_-]+$'
  RESULT=$?

  if [ $# -gt 0 ] || [ $RESULT -eq 0 ]; then
    APP_NAME=$1
  fi
}

set_free_port() {
  FREE_PORT_SITE=$(comm -23 <({ echo 443; seq 8080 8100; }) <(nmap --min-hostgroup 100 -p 443,8080-8100 -sS -n -T4 host.docker.internal | grep 'open' | awk '{print $1}' | cut -d'/' -f1) | head -n 1)
  FREE_PORT_MAILDEV=$(comm -23 <(seq 8010 8100) <(nmap --min-hostgroup 100 -p 8010-8100 -sS -n -T4 host.docker.internal | grep 'open' | awk '{print $1}' | cut -d'/' -f1) | head -n 1)
  sudo -u appuser sed -i "s/443:443/$FREE_PORT_SITE:443/g" docker-compose.yml
  sudo -u appuser sed -i "s/8010:80/$FREE_PORT_MAILDEV:80/g" docker-compose.yml

  URL_SITE=https://$APP_NAME.localhost

  if [ $FREE_PORT_SITE -ne 443 ]; then
    URL_SITE=$URL_SITE:$FREE_PORT_SITE
  fi
}

install() {
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

  set_free_port

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
}

main() {
  parse_options "$@"
  set_app_name "$@"

  tput civis

  echo ''
  echo -e "$success                                                                                                                        $clr"
  echo -e "$success NumberNine installation in progress                                                                                    $clr"
  echo -e "$success                                                                                                                        $clr"
  echo ''
  echo "Creating new project in ./$APP_NAME directory."
  spinner 'Please wait while preparing your project...' &
  PID=$!

  execute install
  RESULT=$?

  kill $PID
  tput cnorm

  if [ $RESULT -eq 0 ]; then
    echo ''
    echo ''
    echo -e "$info                                                                                                                        $clr"
    echo -e "$info What's next?                                                                                                           $clr"
    echo -e "$info                                                                                                                        $clr"
    echo ''
    echo -e "  * ${blue}Read$clr the documentation at ${yellow}https://numberninecms.github.io/$clr"
    echo ''
    echo -e "  * ${blue}Create$clr an admin user with ${yellow}cd $APP_NAME && docker-compose exec php bin/console numbernine:user:create --admin$clr"
    echo ''
    echo -e "  * ${blue}Go$clr to ${yellow}$URL_SITE/admin ${clr}and login with your newly created user"
    echo ''
    echo -e "  * ${blue}Go$clr to ${yellow}http://localhost:$FREE_PORT_MAILDEV/$clr to check mails sent by the app"
  else
    if [ $verbose -eq 0 ]; then
      echo ''
      echo ''
      echo -e "$error                                                                                                                        $clr"
      echo -e "$error An error occurred during installation. What to do next?                                                                $clr"
      echo -e "$error                                                                                                                        $clr"
      echo ''
      echo -e "  * ${blue}Remove$clr the Docker environment with ${yellow}cd $APP_NAME && docker-compose down$clr"
      echo ''
      echo -e "  * ${blue}Remove$clr the project with ${yellow}rm -rf $HOST_PWD/$APP_NAME$clr"
      echo ''
      echo -e "  * ${blue}Relaunch$clr installation with ${yellow}-v${clr} or ${yellow}--verbose${clr} at the end of the command line"
    fi
  fi
}

main "$@"
