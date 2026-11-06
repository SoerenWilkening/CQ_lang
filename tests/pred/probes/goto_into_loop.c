#include "CQ.h"
// USERCHECK h
// cq-0ygtj: rule 14 "Irreducible control flow": a plain goto into a loop body from a quantum test, and a switch elsewhere in
// the function that keeps its form.
int h(int a, int c) {
  cq_theta(&a, 1.0);
  int s = 0, n = a & 3;
  switch (c & 3) {
  case 0: s = 7; break;
  case 1: s = 11; break;
  default: break;
  }
  if (a & 4)
    goto inside;
  while (n > 0) {
    s += 1;
  inside:
    s += 2;
    n--;
  }
  return cq_measure(s);
}
