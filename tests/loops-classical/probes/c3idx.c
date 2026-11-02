/* cq-l56v: a classical value read after a case-3 loop is quantum there (CR rule 14 ruling 2026-11-02): a capture
 * rail. Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec c3idx.c -o c3idx.O1.ll */
#include "CQ.h"
int c3_index(int n, double t) {
  int x = 0; cq_theta(&x, t);
  int i, s = 0;
  for (i = 0; i < n; i++) { s += i * i; if (s == x) break; }
  return cq_measure(i);
}
/* the single-exit form (a mixed latch test `c && !q`): the classical i read after the loop */
int c3_mixed(int n, double t) {
  int x = 0; cq_theta(&x, t);
  int i = 0, s = 0;
  do { i++; s += i; } while (i < n && s != x);
  return cq_measure(i);
}
