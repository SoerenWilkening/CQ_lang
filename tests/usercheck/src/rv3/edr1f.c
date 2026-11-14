/* cq-edr1f (owner ruling 2026-11-11 Q7, CR rule 16 noreturn): exit(5) with classical arguments and no quantum predicate,
   where an abort event can precede it, is the effect entry exit under an alloc_i1(true) seed, then abort_i1 of that
   seed: on an input whose earlier abort fires the exit is never performed. */
#include <stdlib.h>
int f(int a0, double th, int c) {
  int a = a0;
  cq_theta(&a, th);
  if (a & 1) abort();
  if (c & 1) exit(5);
  return cq_measure(a);
}
