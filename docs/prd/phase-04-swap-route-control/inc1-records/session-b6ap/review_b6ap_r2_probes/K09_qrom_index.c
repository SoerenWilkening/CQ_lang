// K09 — the mux is a QROM (const-global) READ INDEX (`lowerQramReads`, :581).
#include <stdio.h>
static const int tab[8] = {3,1,4,1,5,9,2,6};
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  int v = tab[m & 7];
  printf("%d\n", cq_measure(a) + cq_measure(v) + cq_measure(n));
  return 0;
}
