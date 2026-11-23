#!/bin/sh
# build.sh: Stockfish 17 (https://github.com/official-stockfish/Stockfish, tag sf_17) to one LLVM module, build/linked.ll:
# every source file with clang++ -O1 and the flags of its Makefile's general-64 target (no SIMD, -fno-exceptions), the
# network files not embedded. libc++'s std::string bodies are compiled in (_LIBCPP_DISABLE_EXTERN_TEMPLATE). The sources
# are unchanged.
set -eu
cd "$(dirname "$0")"
L=${CQ_LLVM_BIN:-/usr/local/opt/llvm@19/bin}
[ -d src ] || git clone -q --depth 1 --branch sf_17 https://github.com/official-stockfish/Stockfish.git src
mkdir -p build/bc
for f in src/src/*.cpp src/src/nnue/*.cpp src/src/nnue/features/*.cpp src/src/syzygy/*.cpp; do
    "$L/clang++" -std=c++17 -O1 -w -fno-exceptions -DNDEBUG -DIS_64BIT -DNNUE_EMBEDDING_OFF -DUSE_PTHREADS \
        -D_LIBCPP_DISABLE_EXTERN_TEMPLATE -c -emit-llvm "$f" -o "build/bc/$(echo "${f#src/src/}" | tr / _).bc"
done
"$L/llvm-link" -S build/bc/*.bc -o build/linked.ll
echo "functions: $(grep -c '^define ' build/linked.ll)"
