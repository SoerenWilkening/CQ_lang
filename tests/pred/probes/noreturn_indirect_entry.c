#include "CQ.h"
#include <stdlib.h>
// USERCHECK f
// CR rule 16 ("The unreachable after an unconditional noreturn call is a return of zero-valued results", under a quantum
// predicate only: owner ruling 2026-11-14 Q1) with owner ruling 2026-11-11 Q7: quit is called through a noreturn-typed
// function pointer after an abort event. The pointer is read from the bus, an address rail, so the call is rule 19's
// dispatch over the candidates' _ctl clones under their quantum flags, and those come back: the `unreachable` after the
// indirect call is a return of zero. quit's table clone _t (a classical pointer's) ends the shot at abort_i1 of its true
// seed. Before 18b74c94: the `unreachable` stayed (SIGILL on every sample that reached the call).
__attribute__((noinline, noreturn)) void quit(int c) { exit(c); }
typedef void (*nfp)(int) __attribute__((noreturn));
nfp volatile H = quit;
int f(int b, int c) {
  cq_theta(&b, 1.0);
  if (b & 1) abort();
  if (c & 2) H(c & 7);
  return cq_measure(b);
}
