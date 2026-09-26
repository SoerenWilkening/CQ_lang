#!/bin/bash
# link_alloc_variant.sh BUILD_IRPASS_DIR ALLOC_CPP OUT_BIN
# Compile ALLOC_CPP with cq-opt-debugalloc's own flags and re-link cq-opt's objects
# (exactly cq-opt-debugalloc's link line) against it, into OUT_BIN. REVIEW-ONLY.
set -e
B="$1"; SRC="$2"; OUT="$3"
cd "$B"
FLAGS=$(grep '^CXX_FLAGS' CMakeFiles/cq-opt-debugalloc.dir/flags.make | cut -d= -f2-)
DEFS=$(grep '^CXX_DEFINES' CMakeFiles/cq-opt-debugalloc.dir/flags.make | cut -d= -f2-)
INCS=$(grep '^CXX_INCLUDES' CMakeFiles/cq-opt-debugalloc.dir/flags.make | cut -d= -f2-)
/usr/bin/c++ $DEFS $INCS $FLAGS -c "$SRC" -o "$OUT.alloc.o"
LINK=$(cat CMakeFiles/cq-opt-debugalloc.dir/link.txt)
LINK=${LINK//\"CMakeFiles\/cq-opt-debugalloc.dir\/tools\/cq_debug_alloc.cpp.o\"/$OUT.alloc.o}
LINK=${LINK/-o cq-opt-debugalloc/-o $OUT}
eval "$LINK" 2>&1 | grep -v "duplicate libraries" || true
ls -la "$OUT"
