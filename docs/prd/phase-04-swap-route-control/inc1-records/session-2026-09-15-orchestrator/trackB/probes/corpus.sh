#!/bin/bash
# corpus.sh — Track B's ORACLE-vs-SUBJECT sweep (session 2026-09-15).
#
# Derived from `…/session-2026-09-11-orchestrator/review_integration_probes/corpus.sh`
# with three changes, each stated rather than absorbed:
#   1. SUBJ is this worktree;
#   2. the corpus is the PROTOCOL's — `ir-pass/test/*.ll` plus every session
#      dir's `track*/probes` and `review_*_probes/` — enumerated by `find`
#      rather than by a hand-maintained directory list, so a session added since
#      2026-09-11 is not silently skipped;
#   3. ⚠ S3's KNOWN INSTRUMENT HOLE IS CLOSED: the shared tag regex renders the
#      whole `cq_measure_<sfx>` family as an EMPTY `D:`, so a decline->decline
#      string change inside it is INVISIBLE. This version records the sha-256 of
#      the FULL stderr beside the tag, so a string move inside any family is a
#      row move.
#
# A row is `path|<oracle>|<subject>` where each verdict is
#   A:<md5 of the lowered IR, 8 chars>   on exit 0
#   D:<tag>/<sha16 of full stderr>       on a decline
# ⚠ md5s are NOT comparable ACROSS sweeps (the temp ModuleID changes) — compare
# within a row only.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_B
R=$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records
# ⚠ PARALLEL, and the reason is measured rather than stylistic: serial it ran at
# ~27 rows/minute under this box's load (two `cq-opt` spawns plus a `mktemp -d`
# per row), i.e. ~3.5 h for the ~5.6k-row corpus. `-P` is the only change; each
# row is independent, writes only into its own `mktemp -d`, and the output is
# sorted at the end so the file is order-stable across runs.
# ⚠ NEVER relink a binary under a running sweep (`CLAUDE.md`): a whole corpus
# sweep has died mid-run for exactly that, and a failed gate that is really a
# rebuild artefact trains you to discount a real red.
PAR=${CQ_CORPUS_PAR:-4}
OUT=${1:?usage: corpus.sh <out.txt>}
: > "$OUT"

# ⚠ SELF-CHECK, AND IT IS HERE BECAUSE THIS SCRIPT ALREADY LIED ONCE.  The
# parallelising edit above accidentally deleted the `OUT=` assignment; `sort >
# ""` and `echo DONE >> ""` both failed, `2>/dev/null` on the invocation
# swallowed the errors, the run EXITED 0, and the output file still held 45 rows
# from an earlier partial run — so the sweep reported success while measuring
# NOTHING.  `CLAUDE.md` L10 in its purest form: an instrument's failure mode is
# to report a pass.  The guards: the input list must be non-empty, the row count
# must be within 10% of it, and the last line must be `DONE`.  A caller that
# does not see `DONE` has not got a sweep.

list_inputs() {
  find "$SUBJ/ir-pass/test" -name '*.ll' | sort
  find "$R" -type d \( -name probes -o -name 'review_*_probes' -o -name 'merge_gate_probes' \) \
    | sort | while read -r d; do
        find "$d" \( -name '*.c' -o -name '*.ll' \) | sort
      done
}

one_row() {
  local f=$1
  T=$(mktemp -d); rel=${f#$SUBJ/}
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f"); dir=$(dirname "$f")
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}
      libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
      "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null \
        || { echo "$rel|CLANGERR|CLANGERR"; rm -rf $T; return; }
      if [ -n "$libf" ] && [ -f "$libf" ]; then
        "$LLVM/clang" -I$SUBJ/include -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null \
          && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
      else cp "$T/a.ll" "$T/s1.ll"; fi
    elif [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then rm -rf $T; return
    else
      "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
        || { echo "$rel|CLANGERR|CLANGERR"; rm -rf $T; return; }
    fi
  else cp "$f" "$T/s1.ll"; fi
  # ⚠ A 0-BYTE MODULE ACCEPTS through the passthrough early-out (bd memory
  # `empty-module-accepts-vacuity-trap`). Score it as EMPTY, never as ACCEPT.
  if [ ! -s "$T/s1.ll" ]; then echo "$rel|EMPTY|EMPTY"; rm -rf $T; return; fi
  v(){ local root=$1 tag=$2
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll"|cut -c1-8)"
    else echo "D:$(grep -oE 'cq [a-z0-9 ]+: [^\"]+' "$T/$tag.err"|head -1|sed 's/ under quantum control//'|cut -c1-80)/$(shasum -a 256 "$T/$tag.err"|cut -c1-16)"; fi; }
  echo "$rel|$(v $ORC o)|$(v $SUBJ s)"
  rm -rf $T
}
export -f one_row
export LLVM ORC SUBJ

NIN=$(list_inputs | wc -l | tr -d ' ')
if [ "$NIN" -eq 0 ]; then echo "EMPTY CORPUS — harness error, not a clean sweep" >&2; exit 2; fi
list_inputs | xargs -P "$PAR" -I{} bash -c 'one_row "$@"' _ {} | sort > "$OUT"
NROW=$(wc -l < "$OUT" | tr -d ' ')
if [ "$NROW" -lt $((NIN * 9 / 10)) ]; then
  echo "SHORT SWEEP: $NROW rows from $NIN inputs — harness error, not a clean sweep" >&2
  exit 2
fi
echo "DONE inputs=$NIN rows=$NROW" >> "$OUT"
