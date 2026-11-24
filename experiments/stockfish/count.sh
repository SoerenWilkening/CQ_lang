#!/bin/zsh
# count.sh <entries...>: logical gate counts of check.cpp entries (default f1..f5) on the backend's counting gate set.
# Per entry: a main that calls it on one basis value (V, default 28) and measures the result, linked with the check module
# (build/check/check.bc, sf.ll: see check.cpp), reduced to what main reaches, lowered and linked with libcq_gates_count.
# Prints one line per entry. BACKEND picks the archive directory under ../lib (default backend-replay).
H=${0:A:h}; R=${H:h:h}; L=/usr/local/opt/llvm@19/bin; B=$H/build/check; C=$B/count; mkdir -p $C
export CQ_BUILD_DIR=${CQ_BUILD_DIR:-$R/build}
print "entry gates x cnot ccx ry m depth qubits seconds"
[ $# -gt 0 ] || set -- f1 f2 f3 f4 f5
for e in "$@"; do
  print "#define CQ_NO_NEW\n#include \"cq.hpp\"\nextern \"C\" long $e(unsigned char);\nint main() { unsigned char k = ${V:-28}; return (int)cq_measure($e(k)); }" > $C/$e.cpp
  $L/clang++ -std=c++17 -O1 -fno-exceptions -w -I$H/../cxx_rust -c -emit-llvm $C/$e.cpp -o $C/$e.bc &&
  $L/llvm-link $C/$e.bc $B/check.bc $B/sf.ll -o $C/$e.all.bc && $L/opt -passes=internalize,globaldce -internalize-public-api-list=main $C/$e.all.bc -o $C/$e.min.bc &&
  $R/driver/cqcc $C/$e.min.bc -w --backend -L$R/experiments/lib/${BACKEND:-backend-replay} --backend -lcq_backend --backend -lcq_gates_count --backend -lc++ --backend -Wl,-undefined,dynamic_lookup -o $C/$e.q > $C/$e.err 2>&1
  t0=$SECONDS; perl -e 'alarm 900; exec @ARGV' $C/$e.q > $C/$e.out 2>&1; rc=$?
  g() { awk -v k=$1 '$1==k {print $2}' $C/$e.out | tail -1 }
  print "$e $(g gates) $(g x) $(g cnot) $(g ccx) $(g ry) $(g m) $(g depth) $(g qubits) $((SECONDS-t0)) $([ -n "$(g gates)" ] || tail -1 $C/$e.out | cut -c1-110)"
done
