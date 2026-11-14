#include "CQ.h"
#include <stdlib.h>
// USERCHECK f
// CR rule 16 lists __builtin_trap among the noreturn callees; owner ruling 2026-11-11 Q7: on a classical path after a
// quantum abort, the trap is the effect entry __builtin_trap under an alloc_i1(true) seed, then abort_i1 of that seed,
// and the shot ends there (owner ruling 2026-11-14 Q1): the `unreachable` after it stays. The C program ends with the
// trap's signal (SIGILL). Before: the host trap, which ended the shot even where the abort before it had fired (status
// -4 against the C program's -6).
int f(int b, int c) {
  cq_theta(&b, 1.0);
  if (b & 1) abort();
  if (c & 2) __builtin_trap();
  return cq_measure(b);
}
