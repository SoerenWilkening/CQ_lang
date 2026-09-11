// I01 — a 2-phi merge whose ARM holds an I/O sink. `lowerControlledIOSinks`
// (:349) runs BEFORE the peel and is NOT in the four re-asked calls.
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { printf("%d\n", q); m = 7; n = 2; }
  printf("%d %d %d\n", cq_measure(a), m, n);
  return 0;
}
