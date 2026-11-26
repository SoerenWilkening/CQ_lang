/* tests/loops-cutoff noreturn-exit probes (cq-8i5g, CR rule 14 "No live exit", ruling 2026-11-02): an exit edge of a
 * K-loop into a noreturn arm is rule 16's abort arm under that trip's exit flag; a loop whose every exit is such an
 * arm runs its K trips with no continuation. Each entry is checked §6 against its own C program (cqcheck user).
 * Regenerate noexit.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec noexit.c -o noexit.O1.ll */
#include <stdlib.h>
#include "CQ.h"
/* A live exit and an abort exit. */
int na_mixed(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 1;
  do {
    if (((x >> i) & 3) == 2)
      abort();
    acc = acc * 3 + 1;
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
/* Two exits, one into exit(3) after a phase, one live. */
int na_exit(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 0;
  while ((x >> i) & 1) {
    if (((x >> (i + 8)) & 1) != 0) {
      cq_phi(0.25);
      exit(3);
    }
    acc += i + 2;
    i++;
  }
  return cq_measure(acc);
}
/* Every exit is an abort: the loop has no live exit and the function no continuation after it. */
void na_only(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  for (int i = 0;; i++) {
    cq_phi(0.125);
    if (((x | 0x80) >> (i & 7)) & 1)
      abort();
  }
}
/* cq-q7do6 (CR rules 2, 14 "No live exit"; rulings Q3): a measurement in the noreturn arm runs per trip under the trip's exit
 * flag; on a trip the C program goes on from, a quantum test skipped the arm, so that measurement is rule 2's extra one. */
void na_meas(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  for (;;) { int t = x ^ 5; x = x * 3 + 1; if (x & 16) exit(cq_measure(t) & 7); }
}
