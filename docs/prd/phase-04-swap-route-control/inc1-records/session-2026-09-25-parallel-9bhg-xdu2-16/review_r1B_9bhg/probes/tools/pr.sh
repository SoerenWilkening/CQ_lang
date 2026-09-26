#!/bin/bash
# pr.sh <name>...   probes in $S/r1B/p: <name>.c (+ <name>.lib.c or lib.c), args in <name>.args
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
cd $S/r1B/p
for n in "$@"; do
  lib=lib.c; [ -f "$n.lib.c" ] && lib="$n.lib.c"
  if [ ! -f "$n.s1.ll" ] || [ "$n.c" -nt "$n.s1.ll" ] || [ "$lib" -nt "$n.s1.ll" ]; then
    "$L/clang" -O1 -emit-llvm -S "$lib" -o "$n.lib.ll" || { echo "$n: lib compile failed"; continue; }
    "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S "$n.c" -o "$n.caller.ll" || { echo "$n: caller compile failed"; continue; }
    "$L/llvm-link" -S "$n.caller.ll" "$n.lib.ll" -o "$n.s1.ll" || { echo "$n: link failed"; continue; }
  fi
  [ -s "$n.s1.ll" ] || { echo "$n: EMPTY s1"; continue; }
  line="$n"
  for t in preE ora subj; do
    "$S/r1B/cq-opt.$t" -passes=cq-lowering -S "$n.s1.ll" -o "$n.$t.s2.ll" 2> "$n.$t.err"; rc=$?
    er=$(grep -o 'error: .*' "$n.$t.err" | head -1 | sed 's/^error: [^:]*:[0-9:]* //' | cut -c1-90)
    [ $rc -ne 0 ] && rm -f "$n.$t.s2.ll"
    h=""; [ $rc -eq 0 ] && h=$(grep -v '^; ModuleID\|^source_filename' "$n.$t.s2.ll" | shasum -a 256 | cut -c1-8)
    line="$line | $t rc=$rc $h $er"
  done
  echo "$line"
  if [ -f "$n.subj.s2.ll" ]; then
    python3 "$W/tools/free_pairing_check.py" "$n.subj.s2.ll" > "$n.2b" 2>&1; echo "   2b(rc=$?): $(grep -i 'census\|verified' "$n.2b" | tr '\n' ' ' | cut -c1-230)"
    "$L/clang" "$n.subj.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$n.subj.exe" 2>/dev/null || echo "   LINK FAILED"
    args=""; [ -f "$n.args" ] && args=$(cat "$n.args")
    ./"$n.subj.exe" $args > "$n.subj.trace" 2>&1; echo "   run rc=$? trace-lines=$(wc -l < "$n.subj.trace")"
    if [ -f "$n.preE.s2.ll" ]; then
      "$L/clang" "$n.preE.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$n.preE.exe" 2>/dev/null
      ./"$n.preE.exe" $args > "$n.preE.trace" 2>&1
      cmp -s "$n.preE.trace" "$n.subj.trace" && echo "   trace == preE" || echo "   trace DIFFERS from preE"
    fi
  fi
done
