#!/bin/bash
# sweep_one.sh <file.ll> — one corpus row, both binaries.
# Prints: <name>\t<O:exit>\t<O:tag>\t<O:md5>\t<S:exit>\t<S:tag>\t<S:md5>
O=/Users/sorenwilkening/Desktop/Projects/CQ_lang/build
S=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad7349188dd3b67bd/build
f="$1"
n=$(basename "$f")
row="$n"
for B in "$O" "$S"; do
  out=$("$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$f" -o /dev/stdout 2>/tmp/cqsweep.$$.err)
  rc=$?
  tag=$(grep -m1 -o 'error: .*' /tmp/cqsweep.$$.err | sed 's/^error: //; s/^[^ ]*: //; s/in function [^:]*: //')
  [ -z "$tag" ] && tag="-"
  if [ $rc -eq 0 ]; then
    md5=$(printf '%s' "$out" | grep -v '^; ModuleID' | md5 -q)
  else
    md5="-"
  fi
  row="$row	$rc	$tag	$md5"
done
rm -f /tmp/cqsweep.$$.err
printf '%s\n' "$row"
