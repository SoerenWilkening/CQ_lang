/* cq-3kzya (rules 6, 18, 19): a callee rotates a register whose pre-image rule 6 cleaned (t = v * 3; t ^= 11; Ry). The
 * twin is handed the register after its rotation, so it must not clean the old rail against it: it makes no pre-image.
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec twin_rule6_preimage.c -o twin_rule6_preimage.O1.ll */
#include "CQ.h"
__attribute__((noinline)) int bumpq(int v, double th) {
  int t = v * 3;
  t ^= 11;
  cq_theta(&t, th);
  return v * 7;
}
int callq(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  int r = bumpq(x, 0.7);
  return cq_measure(r * r) + cq_measure(x);
}
/* A chain of two updates before the rotation. */
__attribute__((noinline)) int chainq(int v, double th) {
  int t = v * 3;
  t ^= 11;
  t += 2;
  cq_theta(&t, th);
  return v * 7;
}
int callchain(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  int r = chainq(x, 0.7);
  return cq_measure(r * r) + cq_measure(x);
}
/* The old value is read by the result before the update. */
__attribute__((noinline)) int readq(int v, double th) {
  int t = v * 3;
  int w = t * 5;
  t ^= 11;
  cq_theta(&t, th);
  return w;
}
int callread(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  int r = readq(x, 0.7);
  return cq_measure(r * r) + cq_measure(x);
}
