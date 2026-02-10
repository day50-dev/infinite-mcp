#!/bin/bash
if ! which free-ollama 2> /dev/null; then
  curl https://9ol.es/tmp/free-ollama > /tmp/free-ollama
  chmod +x /tmp/free-ollama
  fo=/tmp/free-ollama
else
  fo=$(which free-ollama)
fi

redis-cli del oneque
redis-cli del onequeserver

find gh -mindepth 3 -maxdepth 3 -iname readme.md | sort | xargs -P 30 -n 1 redis-cli rpush oneque
$fo qwen3:8b | xargs -P 30 -n 1 redis-cli rpush onequeserver
