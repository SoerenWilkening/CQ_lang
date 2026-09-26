#!/bin/bash
# mktwins.sh: for each <b>C.c (spec-classical caller), write <b>T.c, the hand-inlined
# twin: h's classical return written directly (h(a,k) = k+1).
cd "$(dirname "$0")/p" || exit 1
for f in *C.c; do
  b="${f%C.c}"
  sed -e 's/int t = h(q, m);/int t = m + 1;/' \
      -e 's/int t2 = h(q, m + 2);/int t2 = m + 3;/' \
      -e '/^int h(int a, int k);$/d' -- "$f" > "${b}T.c"
  if grep -q 'h(q' -- "${b}T.c"; then echo "WARN ${b}T.c still calls h"; fi
done
ls *T.c | wc -l
