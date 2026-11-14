#include "CQ.h"
#include <stdlib.h>
// USERCHECK caller
// USERCHECK chain
// cq-zfrb item 2 with owner ruling 2026-11-11 Q7 (cq-edr1f): the module holds abort events and quit is externally
// visible, so its exit(3) is the effect entry exit under a |1> seed, then abort_i1. quit then comes back (CR rule 16:
// "The unreachable after an unconditional noreturn call is a return of zero-valued results") and loses `noreturn`, and
// so does every in-module call of it: the `unreachable` after the call is a return of zero in the caller as well,
// through two levels (chain -> mid -> quit). Before: the `unreachable` stayed (SIGILL once the seed's flag read 0).
__attribute__((noinline)) void quit(void) { exit(3); }
__attribute__((noinline)) void mid(int c) { quit(); }
int caller(int b, int c) {
  cq_theta(&b, 1.0);
  if (b & 1) abort();
  if (c & 2) quit();
  return cq_measure(b);
}
int chain(int b, int c) {
  cq_theta(&b, 1.0);
  if (b & 1) abort();
  if (c & 2) mid(c);
  return cq_measure(b);
}
