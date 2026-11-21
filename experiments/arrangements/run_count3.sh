#!/bin/zsh
# The consequence tests (i)-(iii): native reference, then each program with this worktree's plugin (new) and, for
# qcount, the reference plugin of HEAD (ref, all-ones clones) on the replay and count backends.
T=${0:A:h}
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang
CL=/usr/local/opt/llvm@19/bin/clang
cd $T
export LIB=qlib ROOTS='evaluate\nsum\n'
for P in qcount3; do
  $CL -O1 -DNATIVE $P.c qlib.c -o native_$P
  echo "== $P native: $(./native_$P; echo "exit $?")"
  echo "-- new replay"; PROG=$P zsh build.sh new $W/build replay
  echo "   calls in main:"; awk '/^define .*@main\(/,/^}/' out/$P-new-replay/prog.ll | grep -o "call [^@]*@[a-z_0-9]*\(evaluate\|sum\)[a-z_0-9]*(" | sort | uniq -c
done
for b in new:build ref:build-m7; do
  echo "== qcount $b count"; PROG=qcount3 zsh build.sh ${b%%:*} $W/${b#*:} count
  [ ${b%%:*} = ref ] && { PROG=qcount3 zsh build.sh ref $W/build-m7 replay; awk '/^define .*@main\(/,/^}/' out/qcount3-ref-replay/prog.ll | grep -o "call [^@]*@[a-z_0-9]*sum[a-z_0-9]*(" | sort | uniq -c; }
done
