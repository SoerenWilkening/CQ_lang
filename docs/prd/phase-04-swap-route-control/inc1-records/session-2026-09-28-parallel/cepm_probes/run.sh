#!/bin/bash
# run.sh TAG [gen|nogen] [member...] : (optionally regenerate) and run twincmp.sh TAG over
# the named members, or over the whole battery (mkprobes.py's list) when none is named.
D="$(cd "$(dirname "$0")" && pwd)"
ALL=$(python3 "$D/mkprobes.py")
TAG="$1"; MODE="$2"; shift 2 2>/dev/null
if [ "$#" -gt 0 ]; then LIST="$*"; else LIST="$ALL"; fi
if [ "$MODE" = gen ]; then
  ARGS=()
  for b in $LIST; do ARGS+=("${b}C" "${b}T"); done
  bash "$D/gen.sh" "${ARGS[@]}"
fi
# shellcheck disable=SC2086
bash "$D/twincmp.sh" "$TAG" $LIST
