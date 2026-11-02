#include "CQ.h"
#include <stdlib.h>
/* cq-2wfi (CR rules 9, 20; gate 2a slots-h1 f2): stores into a fresh malloc cell in sibling arms of a quantum
   if/else are mutually exclusive in C but run one after the other when lowered. Only the first lowered is the
   cell's first write (select(p, v, undef) = v); each later one is guarded over the earlier one's rail. */
int fresh_sibling_arms(int k) {
  int x = 0; cq_theta(&x, 0.5);
  int *a = malloc(8);
  a[1] = 7;
  if (x & 1) a[0] = x * 3;
  else { a[0] = x + 5; a[1] = x ^ 6; }
  int r = a[k & 1];
  free(a);
  return r ^ (k >> 1);
}
/* Three arms (an if/else chain), each storing into a fresh cell; the other cell is written before. */
int fresh_sibling_arms3(int k) {
  int x = 0; cq_theta(&x, 0.5);
  int *a = malloc(8);
  a[1] = k;
  if (x & 1) a[0] = x * 3;
  else if (x & 2) a[0] = x + 5;
  else a[0] = x ^ 6;
  int r = a[k & 1];
  free(a);
  return r ^ (k >> 1);
}
