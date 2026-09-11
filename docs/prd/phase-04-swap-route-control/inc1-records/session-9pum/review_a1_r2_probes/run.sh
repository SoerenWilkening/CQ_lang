#!/bin/bash
# review_a1_r2_probes/run.sh — re-derives every verdict table in review_a1_r2.md
# on BOTH binaries.  Reads nothing, writes nothing outside $TMPDIR.
#   ORACLE  = /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass   (main 0c7380c)
#   SUBJECT = /Users/sorenwilkening/Desktop/CQ_trackA/build/ir-pass (the round-1 fix)
set -u
LLVM=${LLVM:-/usr/local/opt/llvm@19/bin}
ORA=${ORA:-/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass}
SUB=${SUB:-/Users/sorenwilkening/Desktop/CQ_trackA/build/ir-pass}
INC=${INC:-/Users/sorenwilkening/Desktop/CQ_trackA/include}
HERE=$(cd "$(dirname "$0")" && pwd)

verdict() { # $1 = bindir  $2 = s1.ll
  err=$("$1/cq-opt" -load-pass-plugin "$1/libCQPass.so" -passes=cq-lowering -S "$2" -o /dev/null 2>&1)
  if [ $? = 0 ]; then echo "ACCEPT"
  else echo "DECLINE[$(echo "$err" | grep -o 'error: .*' | head -1 | sed 's/^error: //;s/.*: cq /cq /')]"; fi
}
one() { # single TU
  d=$(mktemp -d)
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$1" -o $d/s1.ll 2>/dev/null || { printf '%-28s CLANGFAIL\n' "$(basename $1)"; return; }
  printf '%-28s ORA=%-46s SUBJ=%s\n' "$(basename $1)" "$(verdict "$ORA" $d/s1.ll)" "$(verdict "$SUB" $d/s1.ll)"
  rm -rf $d
}
two() { # caller + lib3.c, per-TU -O1 then llvm-link then ONE cq-lowering
  d=$(mktemp -d)
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -c "$1" -o $d/a.bc 2>/dev/null &&
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -c "$2" -o $d/b.bc 2>/dev/null &&
  "$LLVM/llvm-link" $d/a.bc $d/b.bc -S -o $d/s1.ll 2>/dev/null || { printf '%-28s BUILDFAIL\n' "$(basename $1)"; return; }
  printf '%-28s ORA=%-46s SUBJ=%s\n' "$(basename $1)" "$(verdict "$ORA" $d/s1.ll)" "$(verdict "$SUB" $d/s1.ll)"
  rm -rf $d
}
echo "== F-A1R2-1: the Covered exemption at the two fence-less consumers =="
for f in io0 io1 io3 io4 gs0 gs1 gs2; do one "$HERE/$f.c"; done
two "$HERE/multi/io5.c" "$HERE/multi/lib3.c"
two "$HERE/multi/io3m.c" "$HERE/multi/lib3.c"
echo
echo "== which consumers DO catch the io3 shape (blind-visible staler) =="
for f in c_sel c_kick c_angle c_call c_val c_nest c_abort; do one "$HERE/$f.c"; done
echo
echo "== F-A1R2-2: the InPlaceRailOps crossing HAS a reachable decline face (Q-3) =="
for f in f4a f4f f4g f4h x1 x2 x3 m1; do one "$HERE/$f.c"; done
echo
echo "== F-A1R2-3: the rail-path accept class (F-A1-2) is wider than two programs =="
for f in r1 r2 r3 r4 b3 b4; do one "$HERE/$f.c"; done
echo
echo "== brief S4: the two crossings + Q-5 (Q+Q both operands seeded) =="
for f in f4b f4c f4d f4e; do one "$HERE/$f.c"; done
echo
echo "== brief S6/S7: decline shapes, accept controls, over-decline hunt =="
for f in s01 s02 s03 s04 s05 s06 s07 a01 a02 a03 a04 a05 a06 a07 \
         od1 od1b od2 od3 od4 d3a d3b d3c d3d ab0 ab1 ab2; do one "$HERE/$f.c"; done
echo
echo "== round-2 window (rung iii) at more consumers =="
for f in w3 w6 w8 w9 w10 w11 q4a q4b; do two "$HERE/multi/$f.c" "$HERE/multi/lib3.c"; done
