#!/bin/sh
# q.c with the SQLite amalgamation (src/, from sqlite.org) as one module. Extra arguments go to cqcc.
set -eu
cd "$(dirname "$0")"
. ../common.sh
S=$(echo src/sqlite-amalgamation-*)
cq_run q.c "$S/sqlite3.c" -I"$S" \
    -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_DEFAULT_MEMSTATUS=0 "$@"
