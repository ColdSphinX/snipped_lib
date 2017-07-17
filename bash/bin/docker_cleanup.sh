#!/bin/bash
LOCKFILE=/tmp/docker_cleanup.lock

[ "x$1" = "x-f" ] && rm $LOCKFILE
[ -f "$LOCKFILE" ] && exit 0
touch $LOCKFILE

bigfiles=($(du -hx /var/lib/docker/containers/*/*-json.log | grep ^[1-9][0-9].[0-9]G | awk '{ print $2}'))

if [ ${#bigfiles[@]} -ne 0 ]; then
  for file in ${bigfiles[@]}
  do
    truncate -s 0 "$file"
  done
fi

if [ "$(docker ps -a|grep Exit|cut -d' ' -f 1 | wc -l)" -gt 0 ]; then
  docker ps -a|grep Exit|cut -d' ' -f 1|xargs docker rm
fi

if [ "$(docker ps -a|grep Exit|cut -d' ' -f 1 | wc -l)" -gt 0 ]; then
  docker images -a|grep '^<none>'|tr -s ' '|cut -d' ' -f 3|xargs docker rmi &>/dev/null
fi

rm $LOCKFILE
