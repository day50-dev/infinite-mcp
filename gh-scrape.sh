#!/bin/bash
if [[ ! -d sources/servers ]]; then
  {
    cd sources/servers
    git pull
  }
else
  git clone https://github.com/modelcontextprotocol/servers sources/servers
fi
if [[ ! -d sources/awesome-mcp-servers ]]; then
  {
    cd sources/awesome-mcp-servers
    git pull
  }
else
  git clone https://github.com/punkpeye/awesome-mcp-servers sources/awesome-mcp-servers
fi

cd gh
cat ../sources/servers/README.md ../sources/awesome-mcp-servers/README.md | grep -Po 'https://github.com/[^?#"\s)]*' | grep -E 'https://github[^)]*/[^)]*/[^)]*' | cut -c 20- | cut -d '/' -f 1,2 | sort | uniq | while read i; do
    echo -e "\n\n$i"
    if [[ ! -e "$i" ]]; then
        base="$(dirname $i)";
        [[ -d "$base" ]] || mkdir "$base"
        timeout 10s git clone --depth 1 "https://github.com/$i" "$i"
    else
        (
            cd "$i"
            what=$(git rev-parse --abbrev-ref HEAD)
            timeout 5s git fetch origin $what
            git reset --hard origin/$what
        )
    fi
done
