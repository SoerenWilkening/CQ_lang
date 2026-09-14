#!/bin/zsh
# Track S harness. usage: rs.sh <sub|ora> <probe basenames...>
#
# ⚠ HARDENED AFTER BEING MADE TO FAIL ON PURPOSE (CLAUDE.md L10, 2026-09-14).
# The inherited spelling (trackW/review_r2_probes/rv2.sh) has THREE measured lies,
# all in the PASS direction; each is closed below and each has a selftest case in
# `selftest/`:
#   (1) STALE TRACE. `clang ... && ./a > $P.trace` leaves the PREVIOUS run's trace
#       in place when stage 3 fails, and `wc -l` then reports a count for a run
#       that emitted nothing.  MEASURED: `mutant_stale2` reported `ACCEPT|lines=8`
#       on a module with no `main` that never linked and never ran.
#       -> every artefact for the basename is REMOVED first, and a missing trace
#          after an accept is `LINKFAIL`, never a number.
#   (2) EMPTY MODULE ACCEPTS. A 0-byte `.c` sails through the pass's passthrough
#       early-out and reported `ACCEPT` with stage 2b `0 violation(s)`
#       (bd memory `empty-module-accepts-vacuity-trap`).
#       -> a stage-1 module with no `@cq_` intrinsic call is `VACUOUS-S1`.
#   (3) EMPTY COUNT. `lines=` (no number) was printed as if it were a result.
#       -> the count must be a non-empty integer or the row is `NOTRACE`.
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUB=/Users/sorenwilkening/Desktop/CQ_s82e
ORA=/Users/sorenwilkening/Desktop/CQ_lang
D=${0:h}
WHICH=$1; shift
if [ "$WHICH" = "sub" ]; then B=$SUB; SFX=r2sub; else B=$ORA; SFX=r2ora; fi
if [ "$WHICH" = "sub" ]; then SFX=ssub; else SFX=sora; fi
for P in "$@"; do
  rm -f $D/$P.$SFX.trace $D/$P.$SFX.ll $D/$P.$SFX.err $D/$P.$SFX.s1.ll   # (1) no stale artefact survives
  T=$(mktemp -d)
  "$LLVM/clang" -I$SUB/include -include CQ.h -O1 -g -emit-llvm -S "$D/$P.c" -o $T/s1.ll 2>$T/c.err || { echo "$P|$SFX|STAGE1FAIL"; head -3 $T/c.err; rm -rf $T; continue; }
  if [ ! -s $T/s1.ll ]; then echo "$P|$SFX|EMPTY-S1"; rm -rf $T; continue; fi
  if ! grep -q 'call .*@cq_' $T/s1.ll; then echo "$P|$SFX|VACUOUS-S1 (no @cq_ intrinsic call — the passthrough early-out would ACCEPT nothing)"; rm -rf $T; continue; fi   # (2)
  cp $T/s1.ll $D/$P.$SFX.s1.ll
  "$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $T/s1.ll -o $T/s2.ll 2>$T/o.err
  E=$?
  if [ $E -ne 0 ]; then
    cp $T/o.err $D/$P.$SFX.err
    echo "$P|$SFX|DECLINE|$(grep -o 'cq [a-z -]*lowering: .*' $T/o.err | head -1)|$(grep -o '[A-Za-z0-9_./]*\.c:[0-9]*:[0-9]*' $T/o.err | head -1)"
  else
    if [ ! -s $T/s2.ll ]; then echo "$P|$SFX|EMPTY-S2"; rm -rf $T; continue; fi
    FP=$(python3 $SUB/tools/free_pairing_check.py $T/s2.ll 2>&1 | tail -1)
    cp $T/s2.ll $D/$P.$SFX.ll
    if ! "$LLVM/clang" $T/s2.ll $SUB/build/runtime/libcq_templates.a $SUB/build/runtime/libcq_runtime.a -o $T/a 2>$T/l.err; then
      echo "$P|$SFX|LINKFAIL|$(head -1 $T/l.err)"; rm -rf $T; continue        # (1)
    fi
    $T/a > $D/$P.$SFX.trace || { echo "$P|$SFX|RUNFAIL"; rm -rf $T; continue; }
    N=$(wc -l < $D/$P.$SFX.trace 2>/dev/null | tr -d ' ')
    if [ -z "$N" ]; then echo "$P|$SFX|NOTRACE"; rm -rf $T; continue; fi      # (3)
    echo "$P|$SFX|ACCEPT|lines=$N|$FP"
  fi
  rm -rf $T
done
