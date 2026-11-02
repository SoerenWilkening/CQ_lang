/* cq-kkgh (narrow review w2a-calls4-n1, p5); cq-c09h (owner 2026-11-02): a by-value formal is a copy, so the clone
 * rotates a copy of the caller's u = x + 5; u is untouched by the call and uncomputed as usual.
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec byvalue_rotated.c -o byvalue_rotated.O1.ll */
#include "CQ.h"
static __attribute__((noinline)) int rot(int v, double t) { cq_theta(&v, t); return v; }
int p5(int a0, int b0, double t) {
  int a = a0, b = b0;
  cq_theta(&a, t); cq_theta(&b, t);
  int x = a * b;
  int u = x + 5;
  int w = rot(u, t);
  int r = x * x;
  return cq_measure(w) + cq_measure(r);
}
