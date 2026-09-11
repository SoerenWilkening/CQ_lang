// L06 — the ww4c shift-count (ctlz) idiom over a value the PEEL makes tainted.
// `recognizeCtlzIdiomLoops` (:302) and `lowerLoops` Q1 (:365) both ran while it
// was classical, and neither is re-asked.
#include <stdio.h>
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 1, n = 5;
  if (q == 5) { a = cq_theta(a, 0.9); m = 3; n = 9; }
  int c = 32; unsigned x = (unsigned)m;
  do { c--; x <<= 1; } while ((int)x > 0);
  printf("%d %d %d\n", cq_measure(a), c, cq_measure(n));
  return 0;
}
