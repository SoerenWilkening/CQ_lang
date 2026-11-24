#!/bin/sh
# check.sh SAMPLES ENTRY...: build check.cpp against build/linked.ll and build/libsf.a (from build.sh, build_lib.sh), lower
# it with cqcc (the pass build in CQ_BUILD_DIR, default ../../build) and run cqcheck user on each entry, two at a time.
# A run longer than TIMEOUT seconds (default 300) is killed. Logs and times: build/check/<entry>.log, <entry>.time. SKIP_BUILD=1 reuses build/check/min.ll and minlow.ll.
set -eu
cd "$(dirname "$0")"
R=$(cd ../.. && pwd)
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
export CQ_BUILD_DIR=${CQ_BUILD_DIR:-$R/build}
N=$1; shift
ALL=$(grep -o '^ENTRY long f[0-9]*' check.cpp | sed 's/ENTRY long //' | paste -sd, -)
mkdir -p build/check && cd build/check
if [ "${SKIP_BUILD:-0}" != 1 ]; then
    F="-std=c++17 -O1 -fno-exceptions -DNDEBUG -DIS_64BIT -DNNUE_EMBEDDING_OFF -DUSE_PTHREADS -D_LIBCPP_DISABLE_EXTERN_TEMPLATE -w -I../../src/src -I../../../cxx_rust -I."
    "$L/clang++" $F -DGEN ../../check.cpp ../libsf.a -o gen && ./gen > posdata.inc
    "$L/clang++" $F -DCOUNT ../../check.cpp ../libsf.a -o count && ./count > distinct.txt   # distinct native results per entry
    "$L/clang++" $F -c -emit-llvm ../../check.cpp -o check.bc
    sed 's/@main(/@sf_main(/' ../linked.ll > sf.ll
    "$L/llvm-link" -S check.bc sf.ll -o all.ll
    "$L/opt" -S -passes=internalize,globaldce -internalize-public-api-list="$ALL" all.ll -o min.ll
    "$R/driver/cqcc" -S min.ll -o minlow.ll
fi
export N R T=${TIMEOUT:-300}
printf '%s\n' "$@" | xargs -P 2 -n 1 sh -c '/usr/bin/time -l -o $0.time perl -e "alarm shift; exec @ARGV" $T env PYTHONPATH=$R/checker \
    python3 -m cqcheck user --o1 min.ll --lowered minlow.ll --entry $0 --light --samples $N > $0.log 2>&1
    echo "$0: $(tail -1 $0.log) $(head -1 $0.time)"'
