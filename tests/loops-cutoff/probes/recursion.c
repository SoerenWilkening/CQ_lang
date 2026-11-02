/* tests/loops-cutoff recursion probes (cq-b58q, CR rule 14 "Recursion with quantum depth"): a cut call with a composite
 * result is |0> per quantum field. Each entry is checked §6 against its own C program (cqcheck user).
 * Regenerate recursion.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec recursion.c -o recursion.O1.ll */
#include "CQ.h"
typedef struct { double a, b; } D2;
__attribute__((noinline)) static D2 halves(unsigned n, double v) {
  if (n != 0) {
    D2 r = halves(n - 1, v * 0.5);
    r.a += v;
    r.b -= v * 3.0;
    return r;
  }
  D2 z = {v, v * 0.25};
  return z;
}
/* A struct result: the depth is bounded by n's range (B = 3 <= K), the cut call is |0> in each quantum field. */
double rc_struct(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  D2 r = halves(x & 3, 8.0);
  return cq_measure(r.a) - cq_measure(r.b);
}
