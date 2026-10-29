/* tests/loops-classical slot probes (cq-sujx): rule 14 case 1 with rule 20 slot cells loaded and stored per trip.
 * Each entry is checked §6 against its own C program (cqcheck user). Regenerate slots.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec slots.c -o slots.O1.ll */
#include <stdbool.h>
#include "CQ.h"
/* 58: a register array rotated cell by cell, then measured */
int s_reg(const double *th, int n) {
  bool q[n];
  for (int i = 0; i < n; i++) q[i] = 0;
  for (int i = 0; i < n; i++) cq_theta(&q[i], th[i]);
  int e = 0;
  for (int i = 0; i < n; i++) e += cq_measure(q[i]);
  return e;
}
/* 60 on a local register: a per-trip Toffoli flag over two cells, uncomputed in its own trip */
int s_qft(int n, double base) {
  bool q[n];
  for (int i = 0; i < n; i++) q[i] = 0;
  for (int i = 0; i < n; i++) {
    cq_theta(&q[i], base);
    for (int j = i + 1; j < n; j++)
      if (q[j] && q[i]) cq_phi(base / (double)(1 << (j - i)));
  }
  int e = 0;
  for (int i = 0; i < n; i++) e += cq_measure(q[i]) << i;
  return e;
}
/* int cells: a classical store per trip seeds the cell, rotated in place; a second loop reads two cells per trip */
int s_int(const double *th, int n, int c) {
  int x[n];
  for (int i = 0; i < n; i++) { x[i] = i * c; cq_theta(&x[i], th[i]); }
  int e = 0;
  for (int i = 0; i + 1 < n; i++) if (x[i] == x[i + 1]) cq_phi(th[i]);
  for (int i = 0; i < n; i++) e += cq_measure(x[i]);
  return e;
}
