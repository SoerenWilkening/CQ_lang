#!/bin/bash
# ab.sh file.c|file.ll [clang args...] — stage1 (if .c), stage2 on ORACLE and SUBJECT, 2b, link+run.
# Prints per binary: rc, first error line, 2b summary, trace line count, trace sha.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df
L=/usr/local/opt/llvm@19/bin
SUBJ=$W/build/ir-pass/cq-opt
ORA=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/frozen/cq-opt.main983
f=$1; shift
case "$f" in /*) ;; *) f=./$f ;; esac
case "$f" in
  *.c) b=${f%.c}; "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$@" "$f" -o "$b.s1.ll" || { echo "STAGE1 FAIL"; exit 9; } ; s1=$b.s1.ll ;;
  *.ll) b=${f%.ll}; s1=$f ;;
esac
if [ ! -s "$s1" ]; then echo "EMPTY MODULE $s1"; exit 8; fi
for tag in ORA SUBJ; do
  if [ $tag = ORA ]; then OPT=$ORA; else OPT=$SUBJ; fi
  out=$b.$tag.s2.ll; err=$b.$tag.err
  "$OPT" -passes=cq-lowering -S "$s1" -o "$out" 2> "$err"; rc=$?
  e1=$(grep -m1 'error:' "$err" | sed 's/.*error: //' | cut -c1-160)
  nw=$(grep -c 'warning:' "$err")
  line="$tag rc=$rc warn=$nw ${e1}"
  if [ "$rc" = 0 ]; then
    fp=$(python3 "$W/tools/free_pairing_check.py" "$out" 2>&1 | tail -1 | sed -E 's/.*, ([0-9]+) template rail mint\(s\) of which ([0-9]+) left dirty.*site\(s\): /tmpl=\1 dirty=\2 /')
    if "$L/clang" "$out" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$b.$tag.exe" 2>/dev/null; then
      "$b.$tag.exe" > "$b.$tag.trace" 2>/dev/null
      n=$(wc -l < "$b.$tag.trace" | tr -d ' ')
      sh=$(shasum -a 256 "$b.$tag.trace" | cut -c1-12)
      line="$line | 2b: $fp | trace=$n sha=$sh"
    else line="$line | LINK FAIL"; fi
  fi
  echo "$line"
done
