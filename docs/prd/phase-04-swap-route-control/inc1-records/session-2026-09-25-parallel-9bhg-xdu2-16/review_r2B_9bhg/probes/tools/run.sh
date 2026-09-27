#!/bin/bash
# run.sh NAME BINTAG... : runs each binary on $P/NAME.s1.ll, prints rc + first diag line
P=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r2B9/p; R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r2B9
N=$1; shift
for t in "$@"; do
  case $t in
    subj) cmd="$R/cq-opt.subj";; main) cmd="$R/cq-opt.main";; ora) cmd="$R/cq-opt.ora983";;
    lifo) cmd="env CQ_OPT_DEBUG_ALLOC=lifo $R/cq-opt-debugalloc.subj";; nofree) cmd="env CQ_OPT_DEBUG_ALLOC=nofree $R/cq-opt-debugalloc.subj";;
    gm) cmd="env DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib $R/cq-opt.subj";;
    *) cmd="$t";;
  esac
  $cmd -passes=cq-lowering -S $P/$N.s1.ll -o $P/$N.$t.s2.ll > $P/$N.$t.err 2>&1
  rc=$?
  d=$(grep -v GuardMalloc $P/$N.$t.err | grep -o 'error: .*' | head -1 | cut -c1-150)
  printf '%-22s %-7s rc=%-3s %s\n' "$N" "$t" "$rc" "$d"
done
