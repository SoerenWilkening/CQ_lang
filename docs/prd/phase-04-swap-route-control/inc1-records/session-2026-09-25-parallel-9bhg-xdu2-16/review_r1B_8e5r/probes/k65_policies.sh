#!/bin/bash
# k65 lit-fixture module under 5 allocator policies (my interposer), N runs each.
# usage: k65_policies.sh <label=binary>... ; env N (default 5), MOD (module)
set -u
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
D=$S/rB8/rb8_interpose.dylib
N=${N:-5}
T=$(mktemp -d)
for lb in "$@"; do
  L=${lb%%=*}; B=${lb#*=}
  for m in sys lifo fifo lifo2 nofree; do
    bad=0; crash=0; hs=""
    for i in $(seq 1 $N); do
      if [ $m = sys ]; then "$B" -passes=cq-lowering -S "$MOD" -o $T/t.ll 2>/dev/null; rc=$?
      else DYLD_INSERT_LIBRARIES=$D RB8_ALLOC=$m "$B" -passes=cq-lowering -S "$MOD" -o $T/t.ll 2>/dev/null; rc=$?; fi
      [ $rc -ge 128 ] && crash=$((crash+1))
      grep -q "call i32 @cq_template_mul_i32_hl" $T/t.ll 2>/dev/null && bad=$((bad+1))
      hs="$hs $(shasum -a256 $T/t.ll 2>/dev/null|cut -c1-6)/$rc"
      rm -f $T/t.ll
    done
    echo "$L $m wrong=$bad/$N crash=$crash |$hs"
  done
done
rm -rf $T
