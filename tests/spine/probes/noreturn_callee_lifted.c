/* tests/spine probe (CR rules 16, 18; owner rulings 2026-11-14 Q1, Q7; cq-gk1ki): a defined noreturn function handed a
 * quantum argument or called under a quantum predicate is lifted like any callee with a body; its clone carries the
 * abort form. The table clone of caller calls die's _ctl clone (it stopped with 'a quantum argument to a callee with no
 * clone').
 * Regenerate noreturn_callee_lifted.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h noreturn_callee_lifted.c */
#include <stdlib.h>
__attribute__((noinline, noreturn)) static void die(int a0, double th, int c) {
  int a = a0;
  cq_theta(&a, th);
  if (a & 1) abort();
  exit(c & 7);
}
int caller(int a0, double th, int c) {
  if (c & 2) die(a0, th, c);
  return c;
}
