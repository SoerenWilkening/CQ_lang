#include "CQ.h"
#include <stdlib.h>
// USERCHECK f
// cq-172vi: a noreturn call on the FALSE edge of a compare under a quantum branch (rule 16).
int f(int a) {
  cq_theta(&a, 1.0);
  if (a & 2) abort();
  return cq_measure(a);
}
