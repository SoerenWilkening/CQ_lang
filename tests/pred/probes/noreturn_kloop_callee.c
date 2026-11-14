#include "CQ.h"
#include <stdio.h>
#include <stdlib.h>
// USERCHECK viacall
// USERCHECK direct
// CR rule 14 "No live exit" with owner ruling 2026-11-11 Q7: a K-loop whose only exit leads to a noreturn arm runs its K
// trips, the arm under each trip's exit flag. The arm post-dominates the loop, so taint now makes every block of an
// exit arm control dependent on the exiting branch: in viacall the in-module quit (it came back: its exit is an effect
// entry) is called as its _ctl clone under the flag. Before: quit's own symbol was called on every trip unconditionally,
// so its entry fired on trip 0 (C prints "1\nt0\nt1\n" for b = 3; ours stopped after "t0"). direct is the control.
__attribute__((noinline)) void quit(int c) { exit(c); }
void viacall(int b, int c) {
  cq_theta(&b, 1.0);
  printf("%d\n", b & 1);
  for (int i = 0;; i++) {
    printf("t%d\n", i);
    if (((b >> (i & 31)) & 1) == 0) quit(c & 7);
  }
}
void direct(int b, int c) {
  cq_theta(&b, 1.0);
  printf("%d\n", b & 1);
  for (int i = 0;; i++) {
    printf("t%d\n", i);
    if (((b >> (i & 31)) & 1) == 0) exit(c & 7);
  }
}
