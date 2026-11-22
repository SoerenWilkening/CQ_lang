/* tests/loops-cutoff probes (cq-1jev3, CR rule 14 nested K-loops, "same chain"; TinyEMU main's getopt loop): an inner
 * quantum loop whose live exits meet only through the outer loop's back edge or past the outer loop. The sub-loop's
 * exits meet at one hub of the outer trip (Plugin.cpp unifySubLoopExits), never at the outer header, and a noreturn arm
 * of the inner loop keeps reading the inner trip's own values. Each entry is checked §6 against its own C program
 * (cqcheck user); nest_exits_ir.O1.ll is nest_cont with the outer header taking the inner exit edge directly.
 * Regenerate nest_exits.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec nest_exits.c -o nest_exits.O1.ll */
#include <stdlib.h>
#include "CQ.h"
__attribute__((noinline)) static void tick(int *n) { if (++*n == 3) exit(0); }
/* an inner quantum loop that leaves either into the rest of the outer trip or to the end of the outer trip (a continue
   of the outer loop), in an outer loop with no exit carrying a value */
void nest_cont(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int a = 1, n = 0;
  for (;;) {
    cq_measure(a);
    tick(&n);
    int b = a;
    a = 0;
    for (;;) {
      x = x * 5 + 1;
      if ((x & 3) == 0)
        break;
      if ((x & 3) == 1)
        goto next;
    }
    a = b + 2;
  next:;
  }
}
/* the same in an outer loop with a classical exit */
int nest_cont_ret(int x0, int m, double th) {
  int x = x0; cq_theta(&x, th);
  int a = 1;
  for (int i = 0; i < (m & 3); i++) {
    int b = a;
    a = 0;
    for (;;) {
      x = x * 5 + 1;
      if ((x & 3) == 0)
        break;
      if ((x & 3) == 1)
        goto next;
    }
    a = b + 2;
  next:;
  }
  return a ^ x;
}
/* an inner loop whose noreturn arm reads a value of its trip, its other exits meeting past the outer loop (the
   `return s` inside it): the arm reads t itself, not the exits' hub (base: '%.hub has no value', Context.cpp) */
int nest_abort(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int s = 0;
  for (int i = 0; i < 2; i++) {
    for (;;) {
      int t = x ^ 9;
      x = x * 3 + 1;
      if ((x & 7) == 5) {
        if (t & 2)
          cq_phi(0.25);
        abort();
      }
      if (x & 8)
        break;
      if ((x & 7) == 2)
        return s;
    }
    s += x & 15;
  }
  return s;
}
