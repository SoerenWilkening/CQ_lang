#!/bin/sh
# The repo's checker, light mode, on one entry of a program built by build.sh (see there):
#   softfloat/test/checker/check.sh default|f80 e_<root>      -> build/chk/<entry>.log, the verdict's last line
T=$(cd "$(dirname "$0")" && pwd)
SF=$(dirname "$(dirname "$T")")
D=$SF/build/chk/$1/tmp
HEAVY=${CQ_HEAVY:-/Users/sorenwilkening/Desktop/Projects/wt/heavy.sh}
cd "$SF/../checker" || exit 2
CQCHECK_JOBS=4 nice -n 10 "$HEAVY" -t 300 python3 -m cqcheck user --o1 "$D/linked.ll" --lowered "$D/lowered.ll" \
    --entry "$2" --light --samples 16 > "$SF/build/chk/$2.log" 2>&1
rc=$?
echo "$2 rc=$rc: $(grep -v '^\s*$' "$SF/build/chk/$2.log" | tail -1)"
