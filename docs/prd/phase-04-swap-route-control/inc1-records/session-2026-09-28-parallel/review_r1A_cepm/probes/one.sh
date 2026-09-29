#!/bin/bash
# one.sh name [args...] : run ORACLE and SUBJECT on $P/<name>.s1.ll (or .ll given as path); print rc + first error; if accepts: 2b + trace w/ args
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d
L=/usr/local/opt/llvm@19/bin
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
P="$S/r1A_cepm/p"; b="$1"; shift
IN="$P/$b.s1.ll"; [ -f "$b" ] && { IN="$b"; b=$(basename "$b" .ll); }
for tag in ora new; do
  case $tag in ora) B="$S/frozen/cq-opt.main_9a230646";; new) B="$W/build/ir-pass/cq-opt";; esac
  "$B" -passes=cq-lowering -S "$IN" -o "$P/$b.$tag.ll" 2> "$P/$b.$tag.err"; rc=$?
  e=$(grep -m1 'error:' "$P/$b.$tag.err" | sed 's/^[^ ]*error: //'); w=$(grep -c 'warning:' "$P/$b.$tag.err")
  if [ $rc = 0 ]; then
    tb=$(python3 "$W/tools/free_pairing_check.py" "$P/$b.$tag.ll" 2>&1 | tail -1)
    "$L/clang" "$P/$b.$tag.ll" "$TPL" "$RT" -o "$P/$b.$tag.exe" 2>/dev/null || tb="$tb LINKFAIL"
    if [ "$#" -gt 0 ]; then "$P/$b.$tag.exe" "$@" > "$P/$b.$tag.trace" 2>&1; fi
    echo "$b $tag ACCEPT warn=$w 2b: $tb lines=$(wc -l < "$P/$b.$tag.trace" 2>/dev/null)"
  else echo "$b $tag DECLINE rc=$rc: $e"; fi
done
