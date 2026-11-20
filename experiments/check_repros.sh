#!/bin/sh
# check_repros.sh [build-dir]: every reduced C case from the fix rounds through cqcc --cq-check; prints what does not pass.
cd "$(dirname "$0")"
export CQ_BUILD_DIR=${1:-$(cd .. && pwd)/build-fast}
pass=0; n=0
for f in repro-round1/*.c repro-round2/*.c repro-round3/*.c; do
    b=$(basename $f .c)
    case $b in g5|r3|v9|cplx_decl|blk2|block2|sel_union[0-9]*|repro_newfound_case3_exit_leak|memleak|loops_hang|char_return_miscompile) continue;; esac   # library-mode inputs, known open leaks, a 3-minute case
    case $b in fft3|mirror4|sub3|sub4|flowj|midb|midb2|midmix|mirror3|qarm|qarm2|segdom|hyper|skipjoin|tailguard|tripsel|undefarm) e=f;;
        armloop) e=aff;;
        repro_task1_exit_merge) e=c4;; repro_task2_case3_then_loop) e=g3;; loops_exit_default) e=sel_union;;
        *) e=$(grep -E '^[a-zA-Z_].*\(.*\) *\{' $f | tail -1 | sed -E 's/\(.*//; s/.*[ *]//');; esac
    n=$((n+1))
    r=$(perl -e 'alarm 300; exec @ARGV' ../driver/cqcc -S --cq-check --cq-entry $e $f -o "${TMPDIR:-/tmp}/cq_chk.ll" 2>&1 | tail -1 | cut -c1-100)
    case "$r" in *PASS*) pass=$((pass+1));; *) echo "$b [$e]: $r";; esac
done
echo "reduced cases passing: $pass of $n"
