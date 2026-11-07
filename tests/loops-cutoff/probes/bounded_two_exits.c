/* tests/loops-cutoff probe (cq-v0a5c, CR rules 9, 14): a classically bounded loop with two exit edges and a rail result in a
 * _ctl clone. bt_ret: a `return s * 3` in the loop beside the bound's exit. bt_exit: a classical `exit` arm in such a loop.
 * Regenerate bounded_two_exits.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec bounded_two_exits.c -o bounded_two_exits.O1.ll */
#include "CQ.h"
#include <stdlib.h>
__attribute__((noinline)) int f(int x, int k) {
  cq_phi(.25);
  int s = x;
  for (int i = 0; i < (k & 7); i++) {
    if (k == i + 5)
      return s * 3;
    s += i;
  }
  return s;
}
int bt_ret(int k) {
  char c = 0;
  cq_theta(&c, .5);
  int r = 0;
  if (c & 1)
    r = f(c, k);
  return cq_measure(r + c);
}
__attribute__((noinline)) int g(int x, int k) {
  cq_phi(.25);
  int s = x;
  for (int i = 0; i < (k & 7); i++) {
    if (i == 5)
      exit(4);
    s += i;
  }
  return s;
}
int bt_exit(int k) {
  char c = 0;
  cq_theta(&c, .5);
  int r = 0;
  if (c & 1)
    r = g(c, k);
  return cq_measure(r + c);
}
