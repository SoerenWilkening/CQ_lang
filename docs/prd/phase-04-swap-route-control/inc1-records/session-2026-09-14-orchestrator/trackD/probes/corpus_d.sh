#!/bin/bash
# corpus_d.sh — Track D ORACLE-vs-SUBJECT sweep. Derived from the shared
# `session-2026-09-11-orchestrator/review_integration_probes/corpus.sh`, with two
# deliberate changes:
#   * PROTOCOL S3: the shared tag regex renders a whole diagnostic family as an
#     empty `D:`, so a decline→decline STRING change can be invisible. Every
#     decline row here also carries an md5 of the FULL stderr, so a D→D string
#     change shows up as a row difference.
#   * the corpus adds `tests/e2e/*.c`, because this increment widens a DECLINE and
#     the e2e slice sources are the population a lit-only sweep cannot see (the
#     implementer may not run `^e2e-`; this reads the same .c files without it).
# A row is `path|ORACLE|SUBJECT`; `A:<md5-8 of lowered IR>` or `D:<tag>/<md5-8 of
# full stderr>`. Lowered-IR md5s are compared WITHIN a row only (PROTOCOL S3).
set -u
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_3d8q
R=$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records
OUT=$1
[ "${CORPUS_WORKER:-0}" = "1" ] || : > "$OUT"
emit() {  # $1 = repo root, $2 = tag, $3 = tmpdir
  local root=$1 tag=$2 T=$3
  "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
  if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll" | cut -c1-8)"
  else echo "D:$(grep -oE 'cq [a-z0-9/ ]+: [^\"]+' "$T/$tag.err" | head -1 | sed 's/ under quantum control//' | cut -c1-72)/$(md5 -q "$T/$tag.err" | cut -c1-8)"; fi
}
sweep_file() {
  local f=$1 rel=$2 T
  T=$(mktemp -d)
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f"); dir=$(dirname "$f")
    case "$base" in *_lib.c|lib*.c) rm -rf "$T"; return;; esac
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}; libf="$dir/${stem}_lib.c"
      [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
      "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null \
        || { echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; return; }
      if [ -n "${libf:-}" ] && [ -f "$libf" ]; then
        "$LLVM/clang" -I"$SUBJ/include" -O1 -g -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null \
          && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp -f "$T/a.ll" "$T/s1.ll"
      else cp -f "$T/a.ll" "$T/s1.ll"; fi
    else
      "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
        || { echo "$rel|CLANGERR|CLANGERR" >> "$OUT"; rm -rf "$T"; return; }
    fi
  else cp -f "$f" "$T/s1.ll"; fi
  echo "$rel|$(emit "$ORC" o "$T")|$(emit "$SUBJ" s "$T")" >> "$OUT"
  rm -rf "$T"
}
if [ "${CORPUS_WORKER:-0}" = "1" ]; then sweep_file "$2" "$3"; exit 0; fi

# ── the corpus, as a (path, rel) list, swept 6-way (the sweep is embarrassingly
#    parallel: every row gets its own `mktemp -d`). READ-ONLY on both binaries —
#    never rebuild anything while this is in flight.
LIST=$(mktemp)
find "$SUBJ/ir-pass/test" -name '*.ll' | sort | while read -r f; do
  echo "$f|lit/${f##*/}" >> "$LIST"; done
find "$SUBJ/tests/e2e" -name '*.c' | sort | while read -r f; do
  echo "$f|e2e/${f##*/}" >> "$LIST"; done
for d in session-3qlq4/review_1b_r2_probes session-3qlq4/probes \
         session-9pum/probes session-b6ap/probes session-b6ap/review_b6ap_r2_probes \
         session-f2-i1/probes session-l4x4/probes session-boi6/probes session-r903/probes \
         session-2026-09-11-orchestrator/review_integration_probes \
         session-2026-09-13-orchestrator/trackM/probes/impl \
         session-2026-09-14-orchestrator/trackD/probes/src; do
  [ -d "$R/$d" ] || continue
  find "$R/$d" \( -name '*.c' -o -name '*.ll' \) | sort | while read -r f; do
    echo "$f|${d##*/}/${f##*/}" >> "$LIST"; done
done
tr '|' '\n' < "$LIST" | xargs -P 6 -n 2 env CORPUS_WORKER=1 bash "$0" "$OUT"
sort -o "$OUT" "$OUT"
echo DONE >> "$OUT"
rm -f "$LIST"
