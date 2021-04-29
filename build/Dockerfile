FROM alpine

RUN apk add --no-cache --upgrade sudo openssl bash ncurses grep nmap

COPY --from=docker:latest /usr/local/bin/docker /usr/bin/docker
COPY --from=docker/compose:latest /usr/local/bin/docker-compose /usr/bin/docker-compose

COPY build/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

RUN addgroup -g 1000 -S appgroup && adduser -u 1000 -s /bin/sh -H -D -S appuser -G appgroup

WORKDIR /srv/files

COPY . .

RUN rm -rf build

WORKDIR /srv/app

ENTRYPOINT ["docker-entrypoint"]
