/* tests/uncompute probe (cq-esiw9, CR rules 5, 6, 18): on one classical arm, y = g(&cell) ^ 5 is cleaned (rule 6) against
 * the kept store's value y + 7, which a classical branch puts in a later block of the same arm. y's clean-up runs
 * at the return under its run flag and reads the stored value, which exists wherever the flag holds. Was: the clean-up
 * gave way to y's own _unc, which reads g's result, already zeroed by its twin ('use-after-free: a phi incoming freed on
 * every path to its edge'; GMP 6.3.0 mpn_sqrtrem with mpn_addmul_1's body in the module).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec rule6_arm_exit.c -o rule6_arm_exit.O1.ll */
#include "CQ.h"
long cell, side;
__attribute__((noinline)) static long g(long *p) { return *p > 0; }
long ae(long a, int c, int d) {
  long x = a; cq_theta(&x, 1.0);
  cell = x;
  if (c) return 0;
  long y = g(&cell) ^ 5;
  if (d) side = 1;
  cell = y + 7;
  return 0;
}
