/* cq-nqa6: a multi-exit case-3 loop with the classical bound tested at the header and the quantum exit at the
 * latch, whose classical counter is read after the loop in its exit block (117's is_marked: `k + 1 < n`), then
 * a phase after the classical join of the zero-trip guard and (p_find2) a rotation on the register the loop's
 * records read. Each entry is checked §6 against its own C program. Regenerate mx_read.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec mx_read.c -o mx_read.O1.ll */
#include "CQ.h"
#include <stdbool.h>
static bool is_in(int v, const int *m, int n) {
  for (int k = 0; k < n; k++)
    if (v == m[k]) return true;
  return false;
}
int p_find(int x0, double th, const int *m, int n) {
  int x = x0; cq_theta(&x, th);
  if (is_in(x, m, n)) cq_phi(1.0);
  return cq_measure(x);
}
int p_find2(int x0, double th, const int *m, int n) {
  int x = x0; cq_theta(&x, th);
  if (is_in(x, m, n)) cq_phi(1.0);
  cq_theta(&x, th);
  return cq_measure(x);
}
