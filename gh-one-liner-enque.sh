find gh -mindepth 3 -maxdepth 3 -iname readme.md | sort | xargs -P 30 -n 1 redis-cli rpush oneque
free-ollama qwen3:14b | xargs -P 30 redis-cli rpush onequeserver
