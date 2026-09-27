#!/bin/bash
# C spellings of a callee that READS `a` (live after -O1) yet may return classical.
cd "$(dirname "$0")"
CALLER='#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m) * 3; }'
w() { printf '%s\n' "$CALLER" > "$1.c"; printf '%s\n' "$2" > "$1.lib.c"; }
w c1 '#include <stdio.h>
int h(int a, int k) { if (a > 3) putchar(120); return k + 1; }'
w c2 '#include <stdio.h>
int h(int a, int k) { printf("%d\n", a); return k + 1; }'
w c3 'int sink;
int h(int a, int k) { if (a > 3) sink = 1; return k + 1; }'
w c4 'int sink;
int h(int a, int k) { sink = a; return k + 1; }'
w c5 '#include <stdio.h>
int h(int a, int k) { putchar(a); return k + 1; }'
w c6 'static volatile int Z = 0;
int h(int a, int k) { return (Z ? a : 0) + k + 1; }'
w c7 'int g(int);
int h(int a, int k) { g(a); return k + 1; }'
L=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e
for b in c1 c2 c3 c4 c5 c6 c7; do
  "$L/clang" -O1 -emit-llvm -S -Wno-everything "$b.lib.c" -o "$b.lib.ll"
  "$L/clang" "-I$W/include" -include CQ.h -O1 -emit-llvm -S -Wno-everything "$b.c" -o "$b.caller.ll"
  "$L/llvm-link" -S "$b.caller.ll" "$b.lib.ll" -o "$b.s1.ll"
done
