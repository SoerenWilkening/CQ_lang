/* shape 1 — a state-prep arm whose result is never read (b is dead after -O1: the arm call survives, no merge phi) */
#include "CQ.h"
int main(void){ int a = 0; int b = 0;
  a = cq_theta(a, 0.5);
  if (a == 0){ b = cq_theta(b, 0.5); }
  return cq_measure(a); }
