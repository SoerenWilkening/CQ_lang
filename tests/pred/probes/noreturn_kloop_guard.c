#include "CQ.h"
#include <stdlib.h>
// USERCHECK f
// cq-0etzs: a K-loop with no live exit whose pre-header guard and whose exit edges share one noreturn block (rule 14
// "No live exit", rule 16): the guard's edge is an abort too.
int g;
int f(int a) {
  cq_theta(&a, 1.0);
  int i = 0;
  while (1) {
    if ((a >> i) == 1) exit(0);
    i++;
    g += 1;
  }
  return 0;
}
