/* tests/loops-cutoff trip-object probes (cq-r7-91; CR rules 14, 20, 21; 91's heap_in_loop): a malloc inside a
 * K-loop is one object per (site, trip); the last trip's pointer read after the loop is a fat pointer over null
 * and the trip objects (fatptr R1), its tag advanced by select on the trip predicate; a store into a cell of the
 * trip's fresh block is unguarded (mem-slots freshCell: the old content is undef). Each entry is checked §6
 * against its own C program (cqcheck user). Regenerate trip_objects.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec trip_objects.c -o trip_objects.O1.ll */
#include <stdlib.h>
#include "CQ.h"
/* 91's heap_in_loop. */
int to_last(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned char *last = 0;
  for (unsigned i = 0; i < (x & 3); i++) {
    unsigned char *p = malloc(1);
    p[0] = (unsigned char)(x + i);
    last = p;
  }
  return cq_measure(last ? last[0] : 7);
}
/* Two cells of a four-byte block, read at constant offsets 0 and 2. */
int to_cells(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned char *last = 0;
  for (unsigned i = 0; i < (x & 3); i++) {
    unsigned char *p = malloc(4);
    p[0] = (unsigned char)(x + i);
    p[2] = (unsigned char)(x ^ (i + 5));
    last = p;
  }
  return cq_measure(last ? last[2] + last[0] : 9);
}
/* int cells, a != compare, the read in an arm of its own. */
int to_ne(unsigned x0, double th, int k) {
  unsigned x = x0; cq_theta(&x, th);
  int *last = 0;
  for (unsigned i = 0; i < (x & 3); i++) {
    int *p = malloc(sizeof(int));
    *p = (int)(x * i) + k;
    last = p;
  }
  int r = -1;
  if (last != 0)
    r = *last;
  return cq_measure(r);
}
