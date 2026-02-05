#!/bin/bash
which streamdown > /dev/null || pipx install streamdown
which streamdown > /dev/null || pipx install llcat

model=${MODEL:-qwen3:1.7b}
server=${SERVER:-http://10.0.0.221:11434}
key=${KEY:-}
modulus=${1:-1}
residue=${2:-0}
convo=convo-${residue}.txt

llc() {
  timeout 120s \
      llcat \
    -nw $key \
    -c $convo \
    -u $server \
    -m $model
}

echo "using $model@$server %${residue}=${modulus}"
n=0
find gh -mindepth 3 -maxdepth 3 -iname readme.md | sort | while read i; do
  (( n++ ))
  if (( n % modulus == residue )); then
    truncate -s 0 $convo
    base=$(dirname "$i")
    conf="$base/_one-liner.json" 

    if [[ ! -s "$conf" ]] ; then
      {
        echo "<content>"
        cat "$i"
        echo "</content>"
        echo "<task>"
        cat prompts/one-liner.md
        echo "</task>"
      } | llc -s "You are a Smart Parser. You read a <content> block and a <task> block and output valid JSON. You are not conversational" > "${conf}.raw"

      tries=5
      while true; do
        cat "${conf}.raw" \
          | mq .code \
          | sd -w 1000 --strip \
          | jq -r . > "$conf" 2> ${convo}.err

        ec=$?
        (( tries -- ))
        if [[ "$tries" == 0 ]]; then
          echo "!! $base"
          break
        fi

        if [[ "$ec" != 0 ]]; then
          {
            cat "${conf}".raw
            echo "Let's try this again. I ran `jq .` on that and got"
            cat "${convo}.err"
            echo "As a reminder here is the schema:"
            cat prompts/schema
            echo "If you can't figure out a valid schema there's explicit instructions for that."
          } | llc > "${conf}.raw" 
        else
          break
        fi
      done

      echo "$ec  $base"
    else
      echo "    $base"
    fi
  fi
done
