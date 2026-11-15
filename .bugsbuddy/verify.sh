#!/bin/sh
set -eu
# Trusted base-branch controller. All source/build execution remains in Docker.
tool=$1
shift
cp -R -L /source/. /workspace/
cd /workspace
if [ "$tool" = "kani" ]; then
  manifest=$1; harness=$2; unwind=$3
  cd "$(dirname "$manifest")"
  run_kani() {
    cargo --offline kani --manifest-path Cargo.toml --exact --harness "$harness" --unwind "$unwind" "$@"
  }
  status=0
  run_kani --output-format regular || status=$?
  if [ "$status" -eq 1 ]; then
    printf '\nBUGSBUDDY_KANI_EVIDENCE_BEGIN\n'
    run_kani -Z unstable-options --output-format old --no-slice-formula --cbmc-args --xml-ui --trace ||
      echo "Supplementary evidence was unavailable." >&2
  fi
  exit "$status"
fi
function=$1; unwind=$2; harness=$3
shift 3
/usr/local/bin/goto-cc -DCBMC -I/workspace "$@" "$harness" -o /tmp/bugsbuddy.goto
exec /usr/local/bin/cbmc /tmp/bugsbuddy.goto --function "$function" --unwind "$unwind" \
  --bounds-check --pointer-check --pointer-overflow-check --signed-overflow-check \
  --div-by-zero-check --undefined-shift-check --unwinding-assertions \
  --all-properties --xml-ui --trace
