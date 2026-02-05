#!/bin/bash
onlynew=$1

get_source() {
  path=$(basename $1)

  if [[ -d sources/$path ]]; then
    (
      cd sources/$path
      git pull
    )

  else
    git clone https://github.com/$1 sources/$path
  fi
}

get_source modelcontextprotocol/servers 
get_source punkpeye/awesome-mcp-servers
get_source patriksimek/awesome-mcp-servers-2
touch gh-failure.txt

cd gh
cat ../sources/*/README.md \
  | grep -Po 'https://github.com/[^?#"\s)]*' \
  | grep -E 'https://github[^)]*/[^)]*/[^)]*' \
  | cut -c 20- | cut -d '/' -f 1,2 | sort | uniq | while read i; do
    echo -e "$i"
    if [[ ! -e "$i" ]]; then
      if grep "$i" ../gh-failure.txt; then
        echo "!! $i"
        continue
      fi
      base="$(dirname $i)";
      [[ -d "$base" ]] || mkdir "$base"
      timeout 30s git clone --depth 1 "https://github.com/$i" "$i" || echo "$i" >> ../gh-failure.txt
    else
      [[ -n "$onlynew" ]] && continue
      (
          cd "$i"
          what=$(git rev-parse --abbrev-ref HEAD)
          timeout 5s git fetch origin $what
          git reset --hard origin/$what
      )
    fi
done
