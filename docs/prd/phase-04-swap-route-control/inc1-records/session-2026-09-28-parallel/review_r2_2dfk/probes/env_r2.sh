#!/bin/bash
# r2 probe (E): an UNLISTED env var that steers clang. CLANG_NO_DEFAULT_CONFIG=1
# stops clang 19 reading Homebrew's /usr/local/etc/clang/x86_64-apple-darwin25.cfg,
# which is where `-isysroot <CLT SDK>` comes from; a source that includes an SDK
# header (<stdlib.h>, <stdio.h>) then fails stage 1.
. "$(dirname "$0")/env.sh"
cd "$MY" || exit 2
TE='^e2e-(slice-control-abort|railbank-dynamic-admission-matrix)$'
echo "== warm-up (unmodified env)"; D "$TE" $C | tail -1
echo "== (E) CLANG_NO_DEFAULT_CONFIG=1"
echo -n "  WARM:     "; CLANG_NO_DEFAULT_CONFIG=1 D "$TE" $C -v | tail -8
echo -n "  NO_CACHE: "; CLANG_NO_DEFAULT_CONFIG=1 D "$TE" $C --nocache -v | tail -12
