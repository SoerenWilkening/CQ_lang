#!/bin/bash
# ⚠ COMMITTED COPY of the Track A corpus sweep. The ORC/SUB paths below are this
# session's worktrees and are NOT portable: re-point them before re-running, and
# re-hash both binaries first (PROTOCOL: a gate result is a fact about a BINARY).
# Lowered-IR md5s are NOT comparable across sweeps, which is why the accept rows are
# compared by BYTE (ModuleID/source_filename stripped) and the decline rows by a FULL
# STDERR + EXIT byte compare (PROTOCOL S3: the shared corpus.sh tag regex renders the
# cq_measure_<sfx> family as an empty D:, so a decline->decline string change inside
# it would be INVISIBLE).
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang/build
SUB=/Users/sorenwilkening/Desktop/CQ_xdu2A/build
ROOT=/Users/sorenwilkening/Desktop/CQ_xdu2A
one(){
  f="$1"; rel="${f#$ROOT/}"; T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f")
    case "$base" in *_lib.c|lib*.c) rm -rf "$T"; return;; esac
    "$LLVM/clang" -I$ROOT/include -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR|-"; rm -rf "$T"; return; }
  else cp "$f" "$T/s1.ll"; fi
  "$ORC/ir-pass/cq-opt" -load-pass-plugin "$ORC/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/o.ll" 2>"$T/o.err"; oc=$?
  "$SUB/ir-pass/cq-opt" -load-pass-plugin "$SUB/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s.ll" 2>"$T/s.err"; sc=$?
  ov=$([ $oc -eq 0 ] && echo A || echo D); sv=$([ $sc -eq 0 ] && echo A || echo D)
  if [ "$ov$sv" = "AA" ]; then
    sed -e '/^; ModuleID/d' -e '/^source_filename/d' "$T/o.ll" > "$T/o2"; sed -e '/^; ModuleID/d' -e '/^source_filename/d' "$T/s.ll" > "$T/s2"
    if cmp -s "$T/o2" "$T/s2"; then echo "$rel|A|A|SAME"; else echo "$rel|A|A|IRDIFF"; fi
  elif [ "$ov$sv" = "DD" ]; then
    if cmp -s "$T/o.err" "$T/s.err" && [ $oc -eq $sc ]; then echo "$rel|D|D|SAME"
    else
      om=$(tr -d '\n' < "$T/o.err" | sed 's/.*(): //' | cut -c1-90); sm=$(tr -d '\n' < "$T/s.err" | sed 's/.*(): //' | cut -c1-90)
      od=$(grep -c ':[0-9][0-9]*:[0-9][0-9]*:' "$T/o.err"); sd=$(grep -c ':[0-9][0-9]*:[0-9][0-9]*:' "$T/s.err")
      echo "$rel|D|D|STRMOVE dbg=$od->$sd :: $om >>> $sm"
    fi
  else echo "$rel|$ov|$sv|VERDICTMOVE oc=$oc sc=$sc :: $(tr -d '\n' < $T/o.err | cut -c1-70) >>> $(tr -d '\n' < $T/s.err | cut -c1-70)"; fi
  rm -rf "$T"
}
export -f one; export LLVM ORC SUB ROOT
xargs -P 8 -I{} bash -c 'one "$@"' _ {}
