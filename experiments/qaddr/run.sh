#!/bin/zsh
# run.sh: the quantum-address cases on the replay backend (../lib/backend-replay). e_idx64: a 64-entry table indexed by a
# quantum value. e_ptrN: a pointer loaded from a table of N pointers, then a load through it (N addresses are possible).
# Prints the native and the lowered exit code and, on an abort, the backend's quantum address bit count.
# Measured 2026-11-23 before objects (BACKEND_ABI §1.10): e_ptr2 builds 2^16 leaves, e_ptr4 2^24 and e_ptr64 2^40 (abort).
H=${0:A:h}; R=${H:h:h}; E=$R/experiments/lib; O=$H/out; mkdir -p $O
for s in $H/e_*.c; do p=${s:t:r}
  /usr/local/opt/llvm@19/bin/clang -O1 -w '-Dcq_theta(p,a)=' '-Dcq_measure(x)=(x)' $s -o $O/$p.nat && { $O/$p.nat; n=$?; }
  $R/driver/cqcc $s -w --backend -L$E/backend-replay --backend -lcq_backend --backend -lcq_gates_replay --backend -Wl,-undefined,dynamic_lookup -o $O/$p.q > $O/$p.err 2>&1
  perl -e 'alarm 120; exec @ARGV' $O/$p.q > $O/$p.out 2>&1; r=$?
  echo "$p native=$n lowered=$r $(grep -o 'address rail has [0-9]* quantum bits' $O/$p.out)"
done
