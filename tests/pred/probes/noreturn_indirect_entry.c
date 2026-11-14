#include "CQ.h"
#include <stdlib.h>
// USERCHECK f
// CR rule 16 ("The unreachable after an unconditional noreturn call is a return of zero-valued results") with owner
// ruling 2026-11-11 Q7: quit is called through a noreturn-typed function pointer after an abort event. The call is rule
// 19's dispatch over table clones, and quit's table clone comes back (its exit is the effect entry exit, then abort_i1
// of its seed), so the `unreachable` after the indirect call is a return of zero. Before: it stayed (SIGILL on every
// sample that reached the call).
__attribute__((noinline, noreturn)) void quit(int c) { exit(c); }
typedef void (*nfp)(int) __attribute__((noreturn));
nfp volatile H = quit;
int f(int b, int c) {
  cq_theta(&b, 1.0);
  if (b & 1) abort();
  if (c & 2) H(c & 7);
  return cq_measure(b);
}
