#!/bin/bash
# Track M, Rule-13 review round 1 — SUBJECT vs ORACLE per probe.
# Usage: ./run.sh [probe.c ...]   (default: every *.c in this dir except *_lib.c)
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUBJ=/Users/sorenwilkening/Desktop/CQ_mphi
ORAC=/Users/sorenwilkening/Desktop/CQ_lang
SCR=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/ddf48412-8498-4d8b-9bac-51279fb090c0/scratchpad/trackM_review
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$SCR"

want_s=ae216b3727f5b1ec6e621474631bc99c2225a8edda99cc3c8c5eae1bd942da97
want_o=fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661
got_s=$(shasum -a 256 "$SUBJ/build/ir-pass/cq-opt" | cut -d' ' -f1)
got_o=$(shasum -a 256 "$ORAC/build/ir-pass/cq-opt" | cut -d' ' -f1)
[ "$got_s" = "$want_s" ] || { echo "SUBJECT hash moved: $got_s"; exit 2; }
[ "$got_o" = "$want_o" ] || { echo "ORACLE hash moved: $got_o"; exit 2; }

run_one() {  # $1 = binary root, $2 = tag, $3 = probe path, $4 = extra .c (lib) or ""
  local B=$1 tag=$2 p=$3 lib=${4:-}
  local n; n=$(basename "$p" .c)
  local s1="$SCR/$n.$tag.s1.ll" s2="$SCR/$n.$tag.s2.ll"
  if [ -n "$lib" ]; then
    "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$p"   -o "$SCR/$n.$tag.a.ll" 2>"$SCR/$n.$tag.fe" || { echo "  [$tag] FRONTEND FAIL"; return; }
    "$LLVM/clang" -I"$SUBJ/include" -O1 -g -emit-llvm -S "$lib" -o "$SCR/$n.$tag.b.ll" 2>>"$SCR/$n.$tag.fe" || { echo "  [$tag] FRONTEND FAIL"; return; }
    "$LLVM/llvm-link" -S "$SCR/$n.$tag.a.ll" "$SCR/$n.$tag.b.ll" -o "$s1" || { echo "  [$tag] LINK FAIL"; return; }
  else
    "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$p" -o "$s1" 2>"$SCR/$n.$tag.fe" || { echo "  [$tag] FRONTEND FAIL"; return; }
  fi
  "$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$s1" -o "$s2" 2>"$SCR/$n.$tag.err"; local ec=$?
  local diag; diag=$(grep -o "cq [a-z0-9 -]*lowering: .*" "$SCR/$n.$tag.err" | head -3 | tr '\n' ' | ')
  local nerr; nerr=$(grep -c "error:" "$SCR/$n.$tag.err")
  if [ $ec -ne 0 ]; then
    echo "  [$tag] exit=$ec DECLINE(x$nerr): $diag"
  else
    local pf; pf=$(cd "$SUBJ" && python3 tools/free_pairing_check.py "$s2" 2>&1 | tail -1)
    "$LLVM/clang" "$s2" "$B/build/runtime/libcq_templates.a" "$B/build/runtime/libcq_runtime.a" \
        -o "$SCR/$n.$tag.bin" 2>"$SCR/$n.$tag.link" && "$SCR/$n.$tag.bin" > "$SCR/$n.$tag.trace" 2>&1
    local lines; lines=$(wc -l < "$SCR/$n.$tag.trace" 2>/dev/null || echo "LINKFAIL")
    echo "  [$tag] exit=0 ACCEPT trace=$lines 2b: $pf"
  fi
}

probes=("$@")
if [ ${#probes[@]} -eq 0 ]; then
  probes=($(ls "$HERE"/*.c | grep -v '_lib\.c$'))
fi
for p in "${probes[@]}"; do
  n=$(basename "$p" .c); lib=""
  [ -f "$HERE/${n}_lib.c" ] && lib="$HERE/${n}_lib.c"
  echo "== $n =="
  run_one "$SUBJ" SUBJ "$p" "$lib"
  run_one "$ORAC" ORAC "$p" "$lib"
done
