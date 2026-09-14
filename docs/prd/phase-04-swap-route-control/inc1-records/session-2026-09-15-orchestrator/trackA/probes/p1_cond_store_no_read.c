/* p1_cond_store_no_read.c — Track A, session 2026-09-15, bd `de8n`.
   C7(b) IN ISOLATION: the bank is written from a CONDITIONAL arm and the body
   never READS a cell, so C7(a) holds and only the totality-of-the-WRITE fails.
   On a trip whose condition is false the cell keeps its initializer, so after the
   deferred [N x i8] -> [N x i32] rewrite it reads as handle 0 — a LIVE RAIL. */
#include <stdbool.h>
int slice(int n) {
  bool z = 0;
  bool b[3] = {0};
  for (int i = 0; i < 3; ++i) { if (n > 0) b[i] = cq_theta(z, 0.5); }
  int s = 0;
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s;
}
int main(void) { return slice(2); }
