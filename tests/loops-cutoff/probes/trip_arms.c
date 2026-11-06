/* tests/loops-cutoff probe (CR rules 8, 14): musl __floatscan's "infinity" matcher. A classically bounded loop with a quantum
 * exit whose trip has a classical branch on the index holding a quantum branch: both quantum arms and the classical skip
 * meet at one join. Regenerate trip_arms.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec trip_arms.c -o trip_arms.O1.ll */
#include "CQ.h"
int ta_g;
__attribute__((noinline)) static int more(int v) {
  ta_g += v;
  return v + 1;
}
int ta_scan(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int c = x & 15, r;
  long i;
  for (i = 0; i < 4; i++) {
    if ((c | 32) != 32 + (int)i * 3)
      break;
    if (i < 3) {
      if ((x >> (i + 8)) & 1)
        c = more(c);
      else
        c = (x >> (i + 12)) & 15;
    }
  }
  r = (int)i + c;
  return cq_measure(r);
}
