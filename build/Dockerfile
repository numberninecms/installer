FROM alpine

COPY --from=docker:latest /usr/local/bin/docker /usr/bin/docker
COPY build/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

RUN set -eux; \
    apk add --no-cache --upgrade sudo docker-cli-compose bash acl ncurses grep nmap; \
    chmod +x /usr/local/bin/docker-entrypoint; \
    mkdir /srv/files /app; \
    addgroup -g 1000 -S appgroup; \
    adduser -u 1000 -s /bin/sh -H -D -S appuser -G appgroup; \
    adduser -u 82 -D -S -G www-data www-data; \
    rm -rf build;

COPY . /srv/files/

WORKDIR /app

ENTRYPOINT ["docker-entrypoint"]
