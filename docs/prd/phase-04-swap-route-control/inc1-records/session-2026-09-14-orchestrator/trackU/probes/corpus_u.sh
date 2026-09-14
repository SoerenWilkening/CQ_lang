#!/bin/bash
# corpus_u.sh — Track U's ORACLE-vs-SUBJECT sweep. Derived from
# `session-2026-09-11-orchestrator/review_integration_probes/corpus.sh` with three
# deliberate changes:
#   (1) the corpus is `ir-pass/test/*.ll` FIRST (the population this change moves),
#       then every session probes/ dir PROTOCOL.md lists;
#   (2) a decline row carries the EXIT CODE and a sha256 of the FULL stderr, not
#       only the tag regex — PROTOCOL S3 records that the shared regex renders the
#       whole `cq_measure_<sfx>` family as an empty `D:`, so a decline→decline
#       STRING change inside it is invisible. The sha closes that hole;
#   (3) it runs both binaries on the SAME stage-1 file, in parallel over files.
# Row format:  <rel>|<oracle verdict>|<subject verdict>
#   accept  -> A:<md5 of the lowered IR, first 8>      (comparable WITHIN a row only)
#   decline -> D<exit>:<sha256 of full stderr, first 8>:<first 80 chars of the message>
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_undef
R=$ORC/docs/prd/phase-04-swap-route-control/inc1-records
OUT=$1
JOBS=${2:-4}
: > "$OUT"

list=$(mktemp)
ls "$ORC"/ir-pass/test/*.ll | sort >> "$list"
for d in session-2026-09-14-orchestrator/trackU/probes \
         session-2026-09-13-orchestrator/probes session-2026-09-13-orchestrator/diag_2026-09-14_probes \
         session-2026-09-13-orchestrator/trackC/probes session-2026-09-13-orchestrator/trackM/probes \
         session-2026-09-13-orchestrator/trackR/probes session-2026-09-13-orchestrator/trackL/probes \
         session-2026-09-11-orchestrator/probes session-2026-09-11-orchestrator/review_integration_probes \
         session-9pum/probes session-9pum/review_a1_r1_probes session-9pum/review_a1_r2_probes \
         session-b6ap/probes session-b6ap/review_b6ap_r1_probes session-b6ap/review_b6ap_r2_probes \
         session-f2-i1/probes session-f2-i1/review_f2_r1_probes \
         session-l4x4/probes session-l4x4/review_l4x4b_r1_probes session-l4x4/fix_l4x4b_r1_probes \
         session-boi6/probes session-r903/probes; do
  [ -d "$R/$d" ] || continue
  find "$R/$d" \( -name '*.c' -o -name '*.ll' \) | sort >> "$list"
done
# Track U's own probes live in the SUBJECT worktree (records go there), so add
# them explicitly rather than through $R.
find "$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/probes" \
     \( -name '*.c' -o -name '*.ll' \) 2>/dev/null | sort >> "$list"
sort -u "$list" -o "$list"

one() {
  f="$1"
  T=$(mktemp -d); rel=${f#$R/}; rel=${rel#$ORC/}; rel=${rel#$SUBJ/}
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f"); dir=$(dirname "$f")
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}
      libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
      "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null \
        || { echo "$rel|CLANGERR|CLANGERR"; rm -rf "$T"; return; }
      if [ -n "$libf" ] && [ -f "$libf" ]; then
        "$LLVM/clang" -I"$ORC/include" -O1 -g -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null \
          && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp -f "$T/a.ll" "$T/s1.ll"
      else cp -f "$T/a.ll" "$T/s1.ll"; fi
    elif [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then rm -rf "$T"; return
    else
      "$LLVM/clang" -I"$ORC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
        || { echo "$rel|CLANGERR|CLANGERR"; rm -rf "$T"; return; }
    fi
  else cp -f "$f" "$T/s1.ll"; fi
  v() { local root=$1 tag=$2 rc
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    rc=$?
    if [ $rc -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll" | cut -c1-8)"
    else echo "D$rc:$(shasum -a 256 "$T/$tag.err" | cut -c1-8):$(grep -oE 'cq [a-z0-9_ ]+: [^"]+' "$T/$tag.err" | head -1 | sed 's/ under quantum control//' | cut -c1-80)"; fi; }
  echo "$rel|$(v $ORC o)|$(v $SUBJ s)"
  rm -rf "$T"
}
export -f one; export LLVM ORC SUBJ R
xargs -P "$JOBS" -I{} bash -c 'one "$@"' _ {} < "$list" >> "$OUT"
rm -f "$list"
echo DONE >> "$OUT"
