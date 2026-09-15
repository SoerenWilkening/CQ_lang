#!/bin/bash
# Track A 2026-09-15 — the PROMOTER-OUTPUT differential over a corpus of .ll files.
#
# For each module: run BOTH binaries with CQ_RAILBANK_DBG=1, take (i) the number of
# `promote bank` lines and (ii) the sha256 of the module DUMP that follows the
# fixpoint, and report any row where either differs. The dump is the promoter's
# ACTUAL OUTPUT, so an equal sha256 is a byte-identity statement about the rewrite,
# not merely about the count.
#
# ⚠ INSTRUMENT DISCIPLINE (CLAUDE.md L10, and review_r1a's own `count=0` incident,
# where a broken sweep reported a PASS over a corpus containing ten known-firing
# files). This script SELF-TESTS IN BOTH DIRECTIONS before it reports anything:
# a must-fire control and a must-not-fire control, each checked on BOTH binaries.
# It exits non-zero if either control misbehaves, and it PRINTS THE ROW COUNT.
set -uo pipefail
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/CQ_A/build}
ORAC=${ORAC:-/Users/sorenwilkening/Desktop/CQ_lang/build}
ROOT=/Users/sorenwilkening/Desktop/CQ_A

run() {  # $1=build $2=file  -> "<count> <sha of dump>"
  local out; out=$(CQ_RAILBANK_DBG=1 "$1/ir-pass/cq-opt" -passes=cq-lowering -S "$2" -o /dev/null 2>&1)
  local n; n=$(printf '%s' "$out" | grep -c 'CQ_RAILBANK_DBG: promote bank')
  local d; d=$(printf '%s' "$out" | sed -n '/=== CQ_RAILBANK_DBG: module after/,$p' | shasum -a 256 | cut -c1-16)
  printf '%s %s' "$n" "$d"
}

# ── self-test, both directions, both binaries ──────────────────────────────────
MUSTFIRE="$ROOT/ir-pass/test/railbank_promote_loop_n3.ll"
MUSTNOT="$ROOT/ir-pass/test/lowering_basic.ll"
for B in "$ORAC" "$SUBJ"; do
  read -r NF _ <<<"$(run "$B" "$MUSTFIRE")"
  read -r NN _ <<<"$(run "$B" "$MUSTNOT")"
  [ "$NF" -ge 1 ] || { echo "SELFTEST FAIL: must-fire control fired $NF times in $B"; exit 2; }
  [ "$NN" -eq 0 ] || { echo "SELFTEST FAIL: must-not-fire control fired $NN times in $B"; exit 2; }
done
echo "selftest ok (must-fire >=1, must-not-fire =0, on BOTH binaries)"

ROWS=0; DIFFS=0; FIRES_O=0; FIRES_S=0
for F in "$@"; do
  ROWS=$((ROWS+1))
  O=$(run "$ORAC" "$F"); S=$(run "$SUBJ" "$F")
  ON=${O%% *}; SN=${S%% *}
  [ "$ON" -gt 0 ] && FIRES_O=$((FIRES_O+1))
  [ "$SN" -gt 0 ] && FIRES_S=$((FIRES_S+1))
  if [ "$O" != "$S" ]; then
    DIFFS=$((DIFFS+1)); printf 'MOVER %-60s O:[%s] S:[%s]\n' "$(basename "$F")" "$O" "$S"
  fi
done
echo "rows=$ROWS  promoter-fires ORACLE=$FIRES_O SUBJECT=$FIRES_S  movers=$DIFFS"
