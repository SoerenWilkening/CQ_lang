/* tests/spine probe (CR rule 16 noreturn, owner ruling 2026-11-14 Q1; cq-euke1): under a quantum predicate the `unreachable`
 * after a noreturn call is a return of zero-valued results. `if (x > 3) abort(); exit(0);` has no return: both calls are
 * abort_i1 of a quantum flag, so the run goes on where the flags read 0 and must return (it ran into `unreachable`, SIGILL).
 * The function, its clone and their twins return; the entry loses `noreturn`.
 * Regenerate quantum_dead_end_return.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h quantum_dead_end_return.c */
#include <stdlib.h>
int all_noreturn(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  if (x > 3)
    abort();
  exit(0);
}
