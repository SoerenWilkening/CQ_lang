/* tests/loops-classical fatal probe (cq-w3cd): both quantum arms of a trip hold a classical branch; the first
 * arm's classical region must rejoin before the second arm's code runs (the rejoin of a classical region
 * inside an arm is not built: cq::unimplemented, see run_loops_classical.py FATAL). Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec fatal_rejoin.c -o fatal_rejoin.O1.ll */
#include "CQ.h"
int a_both(int n, int c, double t) {         /* both quantum arms hold classical branches */
  int x = 0; cq_theta(&x, t); int s = 0;
  for (int i = 0; i < n; i++) {
    if (x < 3) { if (c == i) s += x; else s -= 1; } else { if (c < i) s ^= 5; else s += x; }
  }
  return cq_measure(s);
}
