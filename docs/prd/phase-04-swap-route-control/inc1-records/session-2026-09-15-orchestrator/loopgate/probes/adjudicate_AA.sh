#!/bin/bash
# For every ACCEPT->ACCEPT row whose lowered-IR hash MOVED, measure WHAT moved:
# the per-symbol call-count delta between the ORACLE's stream and the MERGED one.
# Track T's bd `tu9q` pairing predicts a delta that is ADDITIONS ONLY, and only of
# `*_unc` (adjoints) and `cqrt_free` (discharges) — i.e. the rolled form emitting
# the discharge the flat form already emitted.  A REMOVED gate, or an added
# non-discharge gate, is NOT the pairing and is a FINDING.
set -u
ORA_BD=/Users/sorenwilkening/Desktop/CQ_lang/build
MRG_BD="$PWD/build"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
pure=0; impure=0
while IFS= read -r rel; do
  f="$PWD/$rel"
  "$ORA_BD/ir-pass/cq-opt" -passes=cq-lowering -S "$f" -o "$W/o.ll" 2>/dev/null || { echo "SKIP(ora-decline) $rel"; continue; }
  "$MRG_BD/ir-pass/cq-opt" -passes=cq-lowering -S "$f" -o "$W/m.ll" 2>/dev/null || { echo "SKIP(mrg-decline) $rel"; continue; }
  grep -o 'call [^@]*@[A-Za-z0-9_]*' "$W/o.ll" | grep -o '@[A-Za-z0-9_]*' | sort | uniq -c > "$W/o.c"
  grep -o 'call [^@]*@[A-Za-z0-9_]*' "$W/m.ll" | grep -o '@[A-Za-z0-9_]*' | sort | uniq -c > "$W/m.c"
  d=$(diff "$W/o.c" "$W/m.c")
  # additions only, and only of _unc / cqrt_free?
  bad=$(printf '%s\n' "$d" | grep '^[<>]' | grep -vE '^[<>] +[0-9]+ @(cq_template_[A-Za-z0-9_]*_unc|cqrt_free)$')
  # a '<' line for a symbol also present on '>' with a LOWER count is a removal
  if [ -z "$bad" ]; then
    pure=$((pure+1)); echo "PAIRING  $rel   [$(printf '%s' "$d" | tr '\n' ' ' | tr -s ' ')]"
  else
    impure=$((impure+1)); echo "⚠ OTHER  $rel"; printf '%s\n' "$d" | sed 's/^/        /'
  fi
done
echo "---- PAIRING-ONLY deltas: $pure ;  OTHER (FINDING candidates): $impure ----"
