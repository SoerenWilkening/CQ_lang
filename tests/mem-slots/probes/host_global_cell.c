#include "CQ.h"
#include <stdio.h>
/* cq-hfah (CR rule 20 per cell): A[0] holds a handle, A[1] never does. A[1] stays a host cell: the classical
   store writes c there (no seed) and the readers read c. Main seeded A[1] (an untainted reader printed the
   handle id) and stopped on the entry's own classical load of it. Readers here: an untainted function
   (report, byte-identical) and the entry itself; host_global_cell_ptr.c reads through a callee's pointer. */
int A[4];
int cnt;
__attribute__((noinline)) void report(void) { printf("%d %d\n", A[1], cnt); }
int e13(int x, double t, int c) {
  A[1] = c;
  cnt = c * 2;
  int q = cq_theta_si32(x, t); A[0] = q;
  report();
  int r = cq_measure_si32(q);
  return r;
}
int same_fn(int x, double t, int c) {
  A[1] = c;
  int q = cq_theta_si32(x, t); A[0] = q;
  printf("%d\n", A[1]);
  return cq_measure_si32(q) + A[1];
}
