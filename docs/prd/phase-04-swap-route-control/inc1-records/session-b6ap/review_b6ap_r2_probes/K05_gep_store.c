// K05 — DELTA COMPLETENESS: a STORE whose POINTER is derived from the mux.
#include <stdio.h>
int g_arr[16];
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  g_arr[m] = 3;
  printf("%d %d %d\n", cq_measure(a), n, g_arr[2]);
  return 0;
}
