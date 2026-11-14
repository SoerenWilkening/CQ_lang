#include "CQ.h"
#include <stdlib.h>
// USERCHECK caller
// USERCHECK chain
// cq-zfrb item 2 with owner rulings 2026-11-11 Q7 (cq-edr1f) and 2026-11-14 (scope of Q7; Q1, cq-9tang): caller calls
// quit, and chain calls it through mid, after an abort event, so quit's own symbol makes exit(3) the effect entry exit
// under a |1> seed, then abort_i1 of that seed: the shot ends there (a classical-valued 1), quit keeps `noreturn` and the
// `unreachable` after it and after each call of it stays, through two levels (chain -> mid -> quit). Only quit's _ctl
// clone comes back (abort_i1 of a quantum predicate). Before Q1: quit came back with a zero-valued return, and so did its
// callers.
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
