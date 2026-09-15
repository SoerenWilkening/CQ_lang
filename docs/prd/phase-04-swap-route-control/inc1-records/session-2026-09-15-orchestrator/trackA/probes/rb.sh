#!/bin/bash
# Track A (session 2026-09-15) rail-bank differential probe: ORACLE vs SUBJECT +
# the two env anchors. Adapted from session-2026-09-14c review_r1a/probes/rb.sh
# (paths + the carve-anchor regex, which now has to survive a second accept
# enumerator). Row:
#   <name> | O:<exit>:<msg> | S:<exit>:<msg> | carve=<verdicts> promo=<n>
# ⚠ VACUITY CONTROL (PROTOCOL S3): a probe with no `cq_*` call is flagged, because
# a 0-byte / intrinsic-free module ACCEPTS through the passthrough early-out.
set -uo pipefail
LLVM=/usr/local/opt/llvm@19/bin
ROOT=/Users/sorenwilkening/Desktop/CQ_A
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/CQ_A/build}
ORAC=${ORAC:-/Users/sorenwilkening/Desktop/CQ_lang/build}
for P in "$@"; do
  B=$(basename "$P"); B="${B%.*}"
  T=$(mktemp -d)
  if [[ "$P" == *.ll ]]; then cp "$P" "$T/s1.ll"; else
    "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$T/s1.ll" 2>"$T/cc.err" || { echo "$B | CLANG-FAIL $(head -1 $T/cc.err)"; continue; }
  fi
  NCQ=$(grep -c 'call .*@cq_\(theta\|phi\|measure\)_' "$T/s1.ll" || true)
  if [ "$NCQ" = "0" ]; then VAC=" !!VACUOUS(no cq_* call)"; else VAC=""; fi
  "$ORAC/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o "$T/o.ll" 2>"$T/o.err"; OE=$?
  "$SUBJ/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s.ll" 2>"$T/s.err"; SE=$?
  OM=$(grep -oE "cq [a-z0-9 -]+:[^,]*" "$T/o.err" | head -1); [ -z "$OM" ] && OM="-"
  SM=$(grep -oE "cq [a-z0-9 -]+:[^,]*" "$T/s.err" | head -1); [ -z "$SM" ] && SM="-"
  CARVE=$(CQ_CTRL_DBG=1 "$SUBJ/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2>&1 | grep -o 'railbank \[[A-Za-z]*\][^ ]* *cells=[0-9]*' | sed 's/railbank //' | tr '\n' ',' )
  [ -z "$CARVE" ] && CARVE="-"
  PROMO=$(CQ_RAILBANK_DBG=1 "$SUBJ/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2>&1 | grep -c 'CQ_RAILBANK_DBG: promote' )
  OCARVE=$(CQ_CTRL_DBG=1 "$ORAC/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2>&1 | grep -o 'railbank \[[A-Za-z]*\][^ ]* *cells=[0-9]*' | sed 's/railbank //' | tr '\n' ',' )
  [ -z "$OCARVE" ] && OCARVE="-"
  OPROMO=$(CQ_RAILBANK_DBG=1 "$ORAC/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2>&1 | grep -c 'CQ_RAILBANK_DBG: promote' )
  FLAG=""
  [ "$OE" != "0" ] && [ "$SE" = "0" ] && FLAG="  *** P1: DECLINE->ACCEPT ***"
  printf '%-36s | O:%s %-52s carve=%-16s promo=%s | S:%s %-52s carve=%-16s promo=%s%s%s\n' \
     "$B" "$OE" "$OM" "$OCARVE" "$OPROMO" "$SE" "$SM" "$CARVE" "$PROMO" "$VAC" "$FLAG"
  rm -rf "$T"
done
