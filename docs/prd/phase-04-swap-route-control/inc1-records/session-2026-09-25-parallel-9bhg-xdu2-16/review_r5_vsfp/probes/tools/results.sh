#!/bin/bash
# results.sh — re-run every review_r5_vsfp probe (bash, not zsh). Rebuilds s1 from csrc/ into a scratch copy,
# lowers with S (subject), R4 (round 4 kept copy) and M (oracle main), 2b STRICT, link, run, and compares
# traces to each probe's hand-inlined twin. Paths of the three binaries are in tools/run.sh.
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
HERE=$(cd "$(dirname "$0")/.." && pwd); WK=$SP/r5rev_rerun; rm -rf $WK; mkdir -p $WK/c $WK/out
cp -f $HERE/tools/build.sh $HERE/tools/run.sh $WK/; cp -f $HERE/csrc/*.c $WK/c/; cp -f $HERE/csrc/ns_*.ll $WK/c/; cd $WK
for n in mt1 mtN mtT tb tsc tuc ts tus tll ti tT tf td tld tfT_float tfT_double tfT_longdouble ps1 ps2 ps1N ps2N psT mt3 mt3N mt3T qr1 qr1N; do ./build.sh c/$n >/dev/null || echo "BUILD FAIL $n"; done
v() { for t in S R4 M; do echo "$1 [$t] $(./run.sh $t c/$1.s1.ll ${2:-5 7})"; done; }
tw() { for t in S R4 M; do [ -f out/$1.s1.$t.trace ] && echo "  $1.$t vs twin $2: $(cmp -s out/$1.s1.$t.trace out/$2.s1.S.trace && echo TRACE-IDENT || echo TRACE-DIFF)"; done; }
echo "== F-Z-1: nested clone, musttail forward of a template rail into a recorded-dead slot (k19 shape)"
for n in mt1 mtN mtT; do v $n; done; tw mt1 mtT; tw mtN mtT
echo "  S call sites:"; grep -o 'call i32 @__cq_q_h[_0-9]*([^)]*)' out/mt1.s1.S.s2.ll | sed 's/^/    /'
echo "  R4 call sites:"; grep -o 'call i32 @__cq_q_h[_0-9]*([^)]*)' out/mt1.s1.R4.s2.ll | sed 's/^/    /'
echo "  S vs twin trace diff:"; diff out/mt1.s1.S.trace out/mtT.s1.S.trace | sed 's/^/    /'
echo "== attack 2: slot-type family (k19 shape; all reach the PRE-spec drop)"
for n in tb tsc tuc ts tus tll ti tT; do v $n; done; for n in tb tsc tuc ts tus tll ti; do tw $n tT; done
for n in tf td tld tfT_float tfT_double tfT_longdouble; do v $n; done; tw tf tfT_float; tw td tfT_double; tw tld tfT_longdouble
echo "== attack 2: narrow-int POST-spec slot (IR) — pre-existing spec decline on all binaries"
for n in ns_sc ns_us ns_b; do for t in S R4 M; do echo "$n [$t] $(./run.sh $t c/$n.ll 5 7)"; done; done
echo "== F-Z-2: #pragma clang section whose KIND does not match the object (object lands in plain __DATA,__data)"
for n in ps1 ps2 ps1N ps2N psT; do v $n 5; done; tw ps1 psT; tw ps2 psT
L=/usr/local/opt/llvm@19/bin; for n in ps1 ps2; do $L/llc -filetype=obj c/$n.s1.ll -o out/$n.o; echo "  $n symbol section: $($L/llvm-objdump -t out/$n.o | grep -E ' _K$| _huge$')"; done
echo "== L2 control: quantum-indexed volatile sectioned table (declines, no initializer read)"
for n in qr1 qr1N; do v $n 5; done
echo "== module-level void musttail (not a customer: the no-op call is removed)"
for n in mt3 mt3N mt3T; do v $n; done; tw mt3 mt3T
