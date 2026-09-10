/* shape 2 — a genuine state prep of b with seed 0 under `a == 0`: seed == the compare constant (drbq Inc-4 fence F2) */
#include "CQ.h"
int main(void){ int a = 0; int b = 0;
  a = cq_theta(a, 0.5);
  if (a == 0){ b = cq_theta(b, 0.5); }
  return cq_measure(a) + cq_measure(b); }
