/* tests/loops-cutoff probe (review R2, bead cq-qotkl; rulings Q3 part 2, Q9; CR rule 2): a quantum branch whose arms all
   measure. The circuit runs the arms in sequence (rule 2), so the arm the C run did not take is measured after the one
   it took: the extra lies between the branch and its join in the C run, where the skip is logged. p14: two quantum arms
   one after the other; sw: a quantum switch with a measurement in each case arm. All §6-equal to their C program.
   Regenerate q3_arms.O1.ll:
   clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec q3_arms.c -o q3_arms.O1.ll */
#include "CQ.h"
int p10(int k) {
  int x = 0, y = 0; short z = 0;
  cq_theta(&x, 0.5); cq_theta(&y, 0.25); cq_theta(&z, 0.75);
  int r;
  if (x > k) r = cq_measure(y) + 1;
  else r = cq_measure(z) * 3;
  return r + cq_measure(x);
}
int p14(int k) {
  int x = 0, y = 0, z = 0;
  cq_theta(&x, 0.5); cq_theta(&y, 0.25); cq_theta(&z, 0.75);
  int r = 0, s = 0;
  if (x > k) r = cq_measure(y);
  if (x < k) s = cq_measure(z);
  return r + s;
}
int sw(int k) {
  int x = 0, y = 0; short z = 0; long long w = 0;
  cq_theta(&x, 0.5); cq_theta(&y, 0.25); cq_theta(&z, 0.75); cq_theta(&w, 0.125);
  int r;
  switch ((x + k) & 3) {
  case 0: r = cq_measure(y) + 1; break;
  case 1: r = cq_measure(z) * 3; break;
  case 2: r = (int)cq_measure(w) - 2; break;
  default: r = 7; break;
  }
  return r + cq_measure(x);
}
