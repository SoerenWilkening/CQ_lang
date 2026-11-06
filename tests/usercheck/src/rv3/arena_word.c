/* cq-6b2cc, CR §6 Pointers: a global's data word that lies in our arena's range is compared by value;
 * a pointer in a global is compared relationally, by the object it names. */
#include "CQ.h"
int g[4];
int a, b;
int *cell;
int f(int x) {
  int v = x;
  cq_theta(&v, .5);
  g[0] = v;
  g[2] = 10;
  g[3] = 10140; /* the word at g[2] is 0x279c0000000a, inside [0x200000000000,0x300000000000) */
  cell = &a;
  return cq_measure(v);
}
