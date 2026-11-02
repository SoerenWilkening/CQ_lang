/* cq-l56v: a classical value read after a case-3 loop is quantum there (CR rule 14 ruling 2026-11-02): a capture
 * rail. Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec c3idx.c -o c3idx.O1.ll */
#include "CQ.h"
int c3_index(int n, double t) {
  int x = 0; cq_theta(&x, t);
  int i;
  for (i = 0; i < n; i++) if (x == i) break;
  return cq_measure(i);
}
