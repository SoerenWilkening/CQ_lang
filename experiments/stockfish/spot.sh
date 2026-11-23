#!/bin/zsh
# spot.sh: each spot check natively and as a lowered program linked with the lowered Stockfish (build/libqsf.a), the lowered C
# library (its wcswcs alias as in ../arrangements/run_libc_check.sh), the native Stockfish and the replay backend; prints both exit codes.
# The classical setup (spot.cpp -DSETUP) is one native object in both builds.
H=${0:A:h}; R=${H:h:h}; L=/usr/local/opt/llvm@19/bin; SRC=$H/src/src; B=$H/build/spot; mkdir -p $B
export CQ_BUILD_DIR=${CQ_BUILD_DIR:-$R/build}
F=(-std=c++17 -O1 -fno-exceptions -DNDEBUG -DIS_64BIT -DNNUE_EMBEDDING_OFF -DUSE_PTHREADS -D_LIBCPP_DISABLE_EXTERN_TEMPLATE -w -I$SRC -I$H/../cxx_rust)
$L/clang++ $F -DSETUP -c $H/spot.cpp -o $B/setup.o || exit 1
for s in ${=SPOTS:-1 2 3 4 5}; do for v in ${=VALS:-28 36 201}; do
  n=$B/s$s.$v
  $L/clang++ $F -DNATIVE -DSPOT=$s -DV=$v $H/spot.cpp $B/setup.o $H/build/libsf.a -Wl,-U,___cq_object -o $n.native 2>$n.nerr && { $n.native; a=$?; } || a=nobuild
  $L/clang++ $F -DSPOT=$s -DV=$v -S -emit-llvm $H/spot.cpp -o $n.ll 2>$n.err &&
  perl -e 'alarm 900; exec @ARGV' $R/driver/cqcc $n.ll --cq-roots $H/build/sf.roots --cq-ext-roots $R/experiments/lib/libc.roots \
    --backend $B/setup.o --backend $H/build/libqsf.a --backend $R/experiments/lib/libqc.a --backend $H/build/libsf.a --backend $H/build/wcswcs.o --backend -L$R/experiments/lib/${BACKEND:-backend-replay} \
    --backend -lcq_backend --backend -lcq_gates_replay --backend -lc++ --backend -Wl,-undefined,dynamic_lookup -o $n.q >> $n.err 2>&1
  if [ -x $n.q ]; then perl -e 'alarm 600; exec @ARGV' $n.q > $n.out 2>&1; b=$?; else b="nolink: $(grep -m1 -iE 'error|undefined' $n.err | cut -c1-150)"; fi
  echo "spot $s v=$v native=$a lowered=$b"
done; done
