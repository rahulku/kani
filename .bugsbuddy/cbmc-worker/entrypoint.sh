#!/bin/sh
set -u

goto_cc=${CBMC_GOTO_CC:-/usr/local/bin/goto-cc}
goto_inspect=${CBMC_GOTO_INSPECT:-/usr/local/bin/goto-inspect}
cbmc=${CBMC_BINARY:-/usr/local/bin/cbmc}
timeout_command=${CBMC_TIMEOUT_COMMAND:-timeout}
function_timeout=${CBMC_FUNCTION_TIMEOUT:-20s}
status=0
index=0

for source in "$@"; do
  unit="/tmp/sabkaproof-${index}.goto"
  compile_status=0
  "$goto_cc" -DCBMC -c "$source" -o "$unit" || compile_status=$?
  if [ "$compile_status" -ne 0 ]; then
    status="$compile_status"
    index=$((index + 1))
    continue
  fi

  functions=$(
    "$goto_inspect" --show-goto-functions "$unit" |
      awk '/^\^+$/{capture=1; next} capture && NF {if ($1 ~ /^[A-Za-z_][A-Za-z0-9_:]*$/) print $1; capture=0}'
  )
  for function in $functions; do
    function_status=0
    "$timeout_command" "$function_timeout" "$cbmc" \
      --object-bits 10 --function "$function" --xml-ui --trace --all-properties "$unit" ||
      function_status=$?
    if [ "$function_status" -eq 124 ]; then
      echo "CBMC function timeout: $function" >&2
    fi
    if [ "$function_status" -ne 0 ]; then
      status="$function_status"
    fi
  done
  index=$((index + 1))
done

exit "$status"