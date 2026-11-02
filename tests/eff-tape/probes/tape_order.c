#include "CQ.h"
#include <stdio.h>
#include <stdlib.h>
/* cq-t8oo / cq-64lv (owner ruling 2026-11-02, CR rule 16, §1.3): once a tape entry or an abort under a
   quantum predicate precedes it, a classical host effect is a tape entry too (C's output order; an
   aborted shot drops it). */
int ord_after_entry(int c) {          /* gate eff-h2 ord1 */
  int x = cq_theta_si32(c, 1.0);
  printf("a %d\n", x);
  int r = cq_measure_si32(x);
  printf("b %d\n", r);
  return r;
}
int ord_after_abort(int c, int k) {   /* gate eff-h2 ab3 */
  int x = cq_theta_si32(c, 1.0);
  if (x == k) abort();
  int r = cq_measure_si32(x);
  printf("after %d\n", r);
  return r;
}
int ord_puts(int c, int k) {
  printf("first %d\n", k);            /* before every tape point: a host call */
  int x = cq_theta_si32(c, 1.0);
  if (x == k) abort();
  int r = cq_measure_si32(x);
  puts("done");
  putchar('0' + (r & 7));
  return r;
}
