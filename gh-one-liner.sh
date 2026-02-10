#!/bin/bash
which streamdown > /dev/null || pipx install streamdown
which llcat > /dev/null || pipx install llcat

model=$1
residue=$2
key=${KEY:-}
convo=convo/${residue}.txt
server=$(redis-cli --raw rpop onequeserver)

llc() {
  timeout 120s \
      llcat \
    -nw $key \
    -c $convo \
    -u $server \
    -m $model
}

echo "using $model@$server %${residue}"
n=0
while true; do
  i=$(redis-cli --raw rpop oneque)
  (( n++ ))
  truncate -s 0 $convo
  base=$(dirname "$i")
  conf="$base/_one-liner.json" 

  if [[ ! -s "$conf" ]] ; then
    while true; do 
      {
        echo "<GitHub URL=\"https://github.com/$base\" />"
        echo "<content filname=\"README.md\">"
        cat "$i"
        echo "</content>"
        echo "<Intructions>"
        cat prompts/one-liner.md
        echo "</Instructions>"
      } | llc -s "You are a Smart Parser. You read a <content> block and a <Instructions> block and output valid JSON. You are not conversational" > "${conf}.raw"

      ec=$?

      [[ "$ec" == 0 ]] && break

      server=$(redis-cli --raw rpop onequeserver)
      if [[ -z "$server" ]]; then
        echo "Woops, nothing left"
        exit
      fi
      echo "Advancing to $server"
    done

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

      [[ "$ec" == 0 ]] && break

      {
        cat "${conf}".raw
        echo "Let's try this again. I ran jq . on that and got"
        cat "${convo}.err"
        echo "As a reminder here is the schema:"
        cat prompts/schema
        echo "If you can't figure out a valid schema there's explicit instructions for that."
      } | llc > "${conf}.raw" 
    done

    echo "$ec  $base"
  else
    echo "   $base"
  fi
done

rm "$convo" "${convo}.err"
