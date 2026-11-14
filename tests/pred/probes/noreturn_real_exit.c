#include "CQ.h"
#include <stdlib.h>
// USERCHECK classical
// USERCHECK classical_switch
// cq-tdqrq: a real host exit ends the shot with rails live. Owner ruling 2026-11-11 Q7 (cq-edr1f): an exit is rule 16's
// ordinary host call only where no tape or abort event can precede it, so these live in a module with no event at all
// (in noreturn_host_end and noreturn_classical_loop every externally visible function is called after an event).

int classical(int b, int c) {
  cq_theta(&b, 1.0);
  int s = b * 3;
  if (c & 1) exit(1);
  if (c & 2) exit(2);
  return cq_measure(s);
}

int classical_switch(int b, int n, int m) {
  cq_theta(&b, 1.0);
  int s = b;
  for (int j = 0; j < n; j++) {
    switch (j - m) {
    case 2: exit(1);
    case 7: exit(2);
    default: break;
    }
    s += j;
  }
  return cq_measure(s);
}
