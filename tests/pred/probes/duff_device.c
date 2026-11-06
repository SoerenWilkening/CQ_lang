#include "CQ.h"
// USERCHECK f
// O1TWIN lower-switch,fix-irreducible
// cq-0ygtj: Duff's device, rule 14 "Irreducible control flow": a switch entering a cycle at several blocks.
int g;
char d[16];
char s[16] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
int f(int a) {
  cq_theta(&a, 1.0);
  int n = a & 7;
  int c = n;
  char *p = d, *q = s;
  if (c) {
    int k = (c + 3) / 4;
    switch (c % 4) {
    case 0:
      do {
        *p++ = *q++;
    case 3:
        *p++ = *q++;
    case 2:
        *p++ = *q++;
    case 1:
        *p++ = *q++;
      } while (--k > 0);
    }
  }
  return cq_measure(d[0]) + 3 * cq_measure(d[1]) + 5 * cq_measure(d[4]);
}
