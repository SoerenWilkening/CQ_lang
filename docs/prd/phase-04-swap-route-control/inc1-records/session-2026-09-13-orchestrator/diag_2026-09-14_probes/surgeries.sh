#!/bin/zsh
# surgeries.sh — the three IR surgeries that NAME the collider (DIAG_2026-09-14 §Q1b).
# They edit ONE constant / delete ONE call in the stage-1 IR and re-run the pass.
#   S1  v6 : %9 = icmp sgt i32 %8, 2  ->  ..., 1     expect ACCEPT  (the pin disappears)
#   S2  v6 : the third region's THETA deleted, %9 and its br KEPT
#            expect DECLINE, same string  (=> the collider is %9, not the theta)
#   S3  w2 : %17 = icmp sgt i32 %16, 2 -> ..., 0     expect the F2 string to MOVE OFF
#            (it becomes 'control flow' — not a clean accept control; see the record)
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="${0:A:h}"; ROOT="${HERE:h:h:h:h:h:h}"; B="$ROOT/build"
OUT="${CQ_DIAG_OUT:-$(mktemp -d)}"; echo "out=$OUT"
gen() { "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$HERE/$1.c" -o "$OUT/$1.s1.ll"; }
runll() { "$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering \
            -S "$1" -o /dev/null 2>"$OUT/$2.err"; echo "$2 exit=$? :: $(head -1 $OUT/$2.err)"; }
gen v6; gen w2
sed 's/icmp sgt i32 %8, 2/icmp sgt i32 %8, 1/' "$OUT/v6.s1.ll" > "$OUT/S1.ll"
python3 - "$OUT/v6.s1.ll" "$OUT/S2.ll" <<'PY'
import re, sys
s = open(sys.argv[1]).read()
s = re.sub(r"  %11 = tail call zeroext i1 @cq_theta_i1\(i1 noundef zeroext false, double noundef 5\.000000e-01\) #2, !dbg !35\n", "", s)
s = re.sub(r"#dbg_value\(i1 %11.*\n", "", s)
s = s.replace("%13 = phi i1 [ %11, %10 ]", "%13 = phi i1 [ false, %10 ]")
open(sys.argv[2], "w").write(s)
PY
sed 's/%17 = icmp sgt i32 %16, 2/%17 = icmp sgt i32 %16, 0/' "$OUT/w2.s1.ll" > "$OUT/S3.ll"
runll "$OUT/S1.ll" S1; runll "$OUT/S2.ll" S2; runll "$OUT/S3.ll" S3
