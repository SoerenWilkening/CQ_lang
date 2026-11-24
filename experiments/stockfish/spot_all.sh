#!/bin/zsh
# spot_all.sh [spots]: each spot check on every value of its 8-bit quantum input, in one program per spot (spot.cpp -DALL):
# the native output and the lowered program's on the replay backend (BACKEND, default backend-replay17) must be equal.
H=${0:A:h}; R=${H:h:h}; L=/usr/local/opt/llvm@19/bin; SRC=$H/src/src; B=$H/build/spot; mkdir -p $B
export CQ_BUILD_DIR=${CQ_BUILD_DIR:-$R/build}
F=(-std=c++17 -O1 -fno-exceptions -DNDEBUG -DIS_64BIT -DNNUE_EMBEDDING_OFF -DUSE_PTHREADS -D_LIBCPP_DISABLE_EXTERN_TEMPLATE -w -I$SRC -I$H/../cxx_rust)
$L/clang++ $F -DSETUP -c $H/spot.cpp -o $B/setup.o || exit 1
for s in ${=@:-1 2 3 4 5}; do n=$B/all$s
  $L/clang++ $F -DNATIVE -DALL -DSTEP=${STEP:-1} -DSPOT=$s $H/spot.cpp $B/setup.o $H/build/libsf.a -Wl,-U,___cq_object -o $n.native && $n.native > $n.nat
  $L/clang++ $F -DALL -DSTEP=${STEP:-1} -DSPOT=$s -S -emit-llvm $H/spot.cpp -o $n.ll 2>$n.err &&
  $R/driver/cqcc $n.ll --cq-roots $H/build/sf.roots --cq-ext-roots $R/experiments/lib/libc.roots \
    --backend $B/setup.o --backend $H/build/libqsf.a --backend $R/experiments/lib/libqc.a --backend $H/build/libsf.a --backend $H/build/wcswcs.o \
    --backend -L$R/experiments/lib/${BACKEND:-backend-replay17} --backend -lcq_backend --backend -lcq_gates_replay --backend -lc++ --backend -Wl,-undefined,dynamic_lookup -o $n.q >> $n.err 2>&1
  t0=$SECONDS; perl -e 'alarm 3000; exec @ARGV' $n.q > $n.low 2>$n.lerr; rc=$?
  echo "spot $s rc=$rc lines=$(wc -l < $n.low | tr -d ' ')/$((256/${STEP:-1})) differing=$(diff $n.nat $n.low | grep -c '^>') time=$((SECONDS-t0))s $(tail -1 $n.lerr | cut -c1-120)"
done
