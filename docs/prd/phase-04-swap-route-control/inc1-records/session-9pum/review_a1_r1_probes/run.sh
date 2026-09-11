#!/bin/bash
# review_a1_r1_probes/run.sh — runs every probe on BOTH binaries and prints the
# verdict table of review_a1_r1.md.  No rebuild, no writes outside $TMP.
#   ORACLE  = /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass   (main 0c7380c)
#   SUBJECT = /Users/sorenwilkening/Desktop/CQ_trackA/build/ir-pass (compare-select-parity)
set -u
LLVM=/usr/local/opt/llvm@19/bin
WT=/Users/sorenwilkening/Desktop/CQ_trackA
OR=/Users/sorenwilkening/Desktop/CQ_lang
HERE="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d)
verdict() { # $1=binary dir  $2=.ll
  "$1/cq-opt" -load-pass-plugin "$1/libCQPass.so" -passes=cq-lowering -S "$2" -o "$T/o.ll" 2>"$T/e"
  if [ $? -eq 0 ]; then echo "ACCEPT"; else
    echo "DECLINE :: $(grep -o 'cq [a-z ]*lowering: .*' "$T/e" | head -1)"; fi
}
one() { # single TU
  local b=$1
  $LLVM/clang -I$WT/include -include CQ.h -O1 -emit-llvm -S "$HERE/$b.c" -o "$T/$b.s1.ll" 2>/dev/null || { echo "$b CLANGFAIL"; return; }
  printf '%-24s ORACLE=%-58s SUBJECT=%s\n' "$b" "$(verdict $OR/build/ir-pass $T/$b.s1.ll)" "$(verdict $WT/build/ir-pass $T/$b.s1.ll)"
}
two() { # $1=caller stem  $2=lib stem  $3=name
  $LLVM/clang -I$WT/include -include CQ.h -O1 -emit-llvm -S "$HERE/$1.c" -o "$T/a.ll" 2>/dev/null
  $LLVM/clang -I$WT/include              -O1 -emit-llvm -S "$HERE/$2.c" -o "$T/b.ll" 2>/dev/null
  $LLVM/llvm-link -S "$T/a.ll" "$T/b.ll" -o "$T/$3.s1.ll"
  printf '%-24s ORACLE=%-58s SUBJECT=%s\n' "$3" "$(verdict $OR/build/ir-pass $T/$3.s1.ll)" "$(verdict $WT/build/ir-pass $T/$3.s1.ll)"
}
ir() { printf '%-24s ORACLE=%-58s SUBJECT=%s\n' "$1" "$(verdict $OR/build/ir-pass $HERE/$1.ll)" "$(verdict $WT/build/ir-pass $HERE/$1.ll)"; }

echo "== F-A1-1  the O-3 residual (BLOCKER).  k7 = k8 + one line; k9 = k7 with that line on ANOTHER register =="
two k7_caller lib3 k7        # ACCEPT on both -- the 9pum wrong stream, unfixed
two k8_caller lib3 k8        # the same program WITHOUT the post-region theta -> DECLINE on the subject
two k9_caller lib3 k9        # post-region theta on another register -> DECLINE on the subject
ir  o3_kick                  # hand-IR form: the increment's own fixture + one instruction

echo "== F-A1-2  O-7's per-activation barrier reaches the RAIL ladder (DECLINE -> ACCEPT) =="
one b1                       # bare _Bool rail, kickback, iteration-local
one b2                       # bare _Bool rail, 4.4 data select, iteration-local
two o7a_caller lib2 o7a      # the barrier's round-2 window -- CLOSED by the ungated rung (ii)
one o7c                      # guarded-only mint: accept on both (control)

echo "== F-A1-3  the cone (O-2) over-declines; and the class is ASYMMETRIC =="
one c1; one c2; one c9; one c10     # ACCEPT on main, DECLINE on the subject
one c7; one c8                      # the MIRROR -- accepts on both
one c3; one c4                      # controls: other register / measure-after

echo "== F-A1-4  the SWITCH parity gap (pre-existing; FILE) =="
ir  sw1                      # switch on a measured scrutinee -> ACCEPT on both
ir  sw2                      # the icmp/br twin of the same program -> DECLINE on the subject

echo "== backstop coverage beyond the two scoped consumers (correct repairs) =="
two k6_caller lib k6         # the SELECT spelling of k7 -- declines on BOTH (gate 2c is position-free)
two g2_caller lib3 g2        # 6.5 classical-call arm
one g3                       # value arm
echo "== O-5: mintCondNetwork is unreachable with a control read (measured) =="
one sp1; one sp2
rm -rf "$T"
