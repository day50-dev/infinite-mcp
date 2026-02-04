#!/bin/bash
#| awk 'BEGIN { show=0; } { if ($1 == "Overview") { show = 1;  } else if ( $0 ~ /© 2025 MCP.so/ ) { show = 0 } else if ( show == 1) { print $0 } } ' | less

model=stepfun/step-3.5-flash:free
server=http://10.0.0.221:11434
server=http://localhost:11434
server=https://openrouter.ai/api
models=( $(llcat -su $server -m | grep :free | shuf) )
n=0
echo "using $model@$server"
find gh -mindepth 3 -maxdepth 3 -iname readme.md | shuf | while read i; do
  base=$(dirname "$i")
  conf="$base/_one-liner.json" 
  if [[ ! -e "$conf" ]] ; then
    cat "$i" | timeout 90s llcat -u $server -m "$model" -k $(<~/openrouter.key) "Find the one-liner way to run this program using a tool such as uvx or npx and if there's any keys that we need. This is usually expressed in JSON with a key of mcpServers. It might also just be uvx or npx. The output should be in the following json format: { 'one_liner': [(the command broken up as an array)], requires: [(what is required to run it such as PLATFORM_KEY or AUTHORIZATION_TOKEN. These should also be an array of strings with each string being the required variable. It should be the LEFT HAND SIDE of the variable. CORRECT: BRAVE_API_KEY. INCORRECT: YOUR_KEY_HERE. Leave the array empty if nothing is needed.)] Do not be conversational. If there is no one-liner, make it the empty-string, represented by \"\"" > "$conf"
    c="$?"
    echo $lc "$base"
    if [[ $lc -ne "0" || ! -s "$conf" ]]; then
      echo "woops: $i"
      continue
      (( n++ ))
      [[ n == ${#models[@]} ]] && n=0
      model="${models[$n]}"
      echo "using next model: $model"
      #sleep 4
    fi
  else
    echo "S $base"
  fi
done
