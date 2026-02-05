#!/bin/bash
which streamdown > /dev/null || pipx install streamdown
which streamdown > /dev/null || pipx install llcat

model=${2:-qwen3:1.7b}
modulus=${3:-1}
residue=${4:-0}
key=${KEY:-}
convo=convo/${residue}.txt
server=$(free-ollama $model $residue)

llc() {
  timeout 120s \
      llcat \
    -nw $key \
    -c $convo \
    -u $server \
    -m $model
}

echo "using $model@$server %${residue}=${modulus}"
off=0
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
      ec=$?

      if [[ "$ec" != "0" ]]; then  
        server=$(free-ollama $model $(( residue + modulus + off)) )
        echo "Advancing to $server"
        (( off ++ ))
      fi

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
            echo "Let's try this again. I ran jq . on that and got"
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
rm $convo
rm ${convo}.err
