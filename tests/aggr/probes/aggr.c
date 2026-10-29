/* tests/aggr probes (cq-w1-aggr): rules 25 and 26 lane and field constructions inside one function, each entry
 * checked §6 against its own C program (cqcheck user). Regenerate aggr.O1.ll: clang -O1 -S -emit-llvm
 * -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec aggr.c -o aggr.O1.ll */
#include "CQ.h"
typedef float v2f __attribute__((ext_vector_type(2)));
typedef unsigned v4u __attribute__((ext_vector_type(4)));
typedef int v4i __attribute__((ext_vector_type(4)));

/* a quantum lane and a classical lane, a lane swap, a per-lane product; lane 1 of the product is unread */
float p_vlanes(float a0, double th, float b, float c) {
  float a = a0; cq_theta(&a, th);
  v2f v = {a, b};
  v2f w = v + (v2f){c, c};
  v2f t = w * w.yx;
  return cq_measure(t.x + t.y);
}
/* int lanes: a reversing shuffle, per-lane add, mul and shift; vector operands are values, not constants
 * (cq-ykdl: the checker does not probe vector constants yet) */
unsigned p_vint(unsigned x0, double th, unsigned c, unsigned d, unsigned k) {
  unsigned x = x0; cq_theta(&x, th);
  v4u v = {x, c, x * d, d};   /* x * d, not x ^ d: cq-qasj */
  v4u s = v.wzyx + v;
  v4u m = s * (v4u){c, d, k, c};
  v4u r = m >> (v4u){k & 7, 2 + (k & 3), k & 15, k & 1};
  return cq_measure(r.x ^ r.y ^ r.z ^ r.w);
}
/* overflow struct fields: value and flag */
unsigned p_ovf(unsigned x0, double th, unsigned c) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r;
  int o = __builtin_mul_overflow(x, c, &r);
  return cq_measure(r + (unsigned)o);
}
