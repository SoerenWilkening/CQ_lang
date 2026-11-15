/* tests/loops-cutoff probe (cq-9kcq S21; CR rules 14, 26): a vector (clang's vector extension) computed in the header test
 * region of a quantum-exit K-loop (region form: the header exits, the body exits too) and read by the body: the rolled trip
 * carries it one field per header phi. Internal error at c807cdf5 (spine operand() of a value with 2 fields). Checked
 * against the C program; mutant other_field: field 1's carried phi takes field 0's latch value.
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec agg_region.c -o agg_region.O1.ll */
#include "CQ.h"
typedef int v2 __attribute__((vector_size(8)));
__attribute__((noinline)) static int g(int a) { return a * 5 + 1; }
int vec_region(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int acc = 0;
  v2 w;
  for (;;) {
    w = (v2){(int)x, (int)x * 3} * (v2){(int)x, 7};
    if (w[0] & 4) break;
    acc = g(acc ^ w[1]); x >>= 1;
    if (acc & 8) return cq_measure(acc);
  }
  return cq_measure(acc - 1);
}
