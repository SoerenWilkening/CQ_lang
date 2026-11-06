/* tests/loops-cutoff probe (CR rule 6, both operands dead): musl strncmp's shape. `a - b` of two dead rails is an arm of a
 * classical phi: one is cleaned from the difference on the path that chose it, the other kept. Regenerate
 * both_dead_merge.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec both_dead_merge.c -o both_dead_merge.O1.ll */
#include "CQ.h"
int bd_merge(int x0, long n, double th) {
  unsigned char x = (unsigned char)x0; cq_theta(&x, th);
  int r = 0;
  if (n) {
    unsigned char y = x + 3;
    r = (int)x - (int)y;
  }
  return cq_measure(r + (x & 1));
}
