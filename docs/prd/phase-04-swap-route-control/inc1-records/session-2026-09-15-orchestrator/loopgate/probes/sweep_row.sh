#!/bin/bash
# one corpus row; invoked by sweep_gate.sh via xargs -P. Args: <cq-opt> <plugin> <root> <file>
CQ="$1"; PL="$2"; ROOT="$3"; f="$4"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
rel="${f#$ROOT/}"
err=$("$CQ" -load-pass-plugin "$PL" -passes=cq-lowering -S "$f" -o "$W/o.ll" 2>&1); e=$?
if [ $e -eq 0 ]; then
  h=$(grep -v '^; ModuleID' "$W/o.ll" | grep -v '^source_filename' | shasum -a 256 | cut -c1-16)
  printf '%s|A|%s|\n' "$rel" "$h"
else
  eh=$(printf '%s' "$err" | shasum -a 256 | cut -c1-16)
  s=$(printf '%s' "$err" | grep -o 'cq [a-z0-9 -]*\(lowering\|escape\|propagation\)[^|]*' | head -1)
  [ -z "$s" ] && s="<NO-REGEX-MATCH>"
  printf '%s|D%s|%s|%s\n' "$rel" "$e" "$eh" "$s"
fi
