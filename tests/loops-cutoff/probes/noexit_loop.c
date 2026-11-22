/* tests/loops-cutoff probes (cq-hmxd5, CR rule 14 "No live exit"): a loop with no exit edge at all whose body is
 * quantum (Game of Life's while (1), TinyEMU's for (;;)), left only through exit() in a callee; and a K-loop whose
 * only exits are noreturn arms, one reading a value of the trip (TinyEMU's getopt loop, cq-hmxd5's segfault).
 * Each entry is checked §6 against its own C program (cqcheck user).
 * Regenerate noexit_loop.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec noexit_loop.c -o noexit_loop.O1.ll */
#include <stdlib.h>
#include "CQ.h"
__attribute__((noinline)) static void tick(int *n) { if (++*n == 3) exit(0); }
/* no test in the body */
void ne_call(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int n = 0;
  while (1) { x = x * 3 + 1; cq_measure(x); tick(&n); }
}
/* a quantum test in the body */
void ne_qif(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int n = 0;
  for (;;) { if (x & 1) x += 5; else x ^= 3; cq_measure(x); tick(&n); }
}
/* a classical test in the body */
void ne_cif(int x0, int c, double th) {
  int x = x0; cq_theta(&x, th);
  int n = 0;
  for (;;) { if (c & 1) x += 5; c >>= 1; tick(&n); cq_measure(x); }
}
/* in a quantum arm */
void ne_arm(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int n = 0;
  if (x & 8) {
    for (;;) { x = x * 3 + 1; cq_measure(x); tick(&n); }
  }
  n = cq_measure(x);
  exit(n & 1);
}
/* after a quantum test into exit(), as TinyEMU's main */
void ne_after_exit(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int n = 0;
  if (x & 8)
    exit(1);
  for (;;) { x = x * 3 + 1; cq_measure(x); tick(&n); }
}
/* every exit a noreturn arm that reads a value of the trip (TinyEMU's getopt loop, which no live exit follows) */
void ne_arm_reads(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  for (;;) {
    int t = x ^ 5;
    x = x * 3 + 1;
    if (x & 16) {
      if (t & 2)
        cq_phi(0.25);
      abort();
    }
  }
}
