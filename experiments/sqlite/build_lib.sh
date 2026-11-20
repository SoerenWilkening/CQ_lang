#!/bin/sh
# One-time: lowers SQLite as a library, ../lib/libqsqlite.a. ROOTS names the exported functions
# (default core.roots, the API q.c uses). Everything they reach is lowered with all arguments quantum.
set -eu
cd "$(dirname "$0")"
S=$(echo src/sqlite-amalgamation-*)
ROOTS=${ROOTS:-core.roots}

time ../../driver/cqcc --cq-lib --cq-roots "$ROOTS" --cq-ext-roots ../lib/libc.roots "$S/sqlite3.c" -w \
    -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_DEFAULT_MEMSTATUS=0 \
    --save-temps build/lib -o ../lib/libqsqlite.a "$@"
ls -la ../lib/libqsqlite.a
