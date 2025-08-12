#!/bin/sh
# wait-for-it.sh: Wait until a host:port is available
# Usage: wait-for-it.sh host:port -- command args

HOSTPORT="$1"
shift

HOST=$(echo $HOSTPORT | cut -d: -f1)
PORT=$(echo $HOSTPORT | cut -d: -f2)

while :
do
  nc -z "$HOST" "$PORT" && break
  echo "Waiting for $HOST:$PORT..."
  sleep 1
done
exec "$@"
