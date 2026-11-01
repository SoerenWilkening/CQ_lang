/* cq-igqp: a loop-carried register rotated in place (cq_theta) inside a loop. A classically bounded loop's header
 * phi over handles names the initial rail on trip 0, so the rotation is a non-diagonal gate on that rail too: its
 * producer is never uncomputed through it (CR §0, rule 10: the rail stays allocated). Each entry is checked §6
 * against its own C program (no residue, no dirty free). Regenerate carried_rot.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec carried_rot.c -o carried_rot.O1.ll */
#include "CQ.h"
/* Gate 2a review unc-h2 p38: x = x + 1 (garbage of the add) carried and rotated in the trip. */
int p38(int x0, int n, double th) {
  int x = x0;
  cq_theta(&x, th);
  int a = x;
  x = x + 1;
  int r = 0;
  for (int i = 0; i < n; i++) {
    r ^= cq_measure(a * 5 + i);
    cq_theta(&x, th);
  }
  return r ^ cq_measure(x);
}
/* A quantum bound (rule 14 case 2, the cutoff at K) whose trip rotates a carried garbage rail. */
int p38_cut(int x0, int b0, double th) {
  int x = x0, b = b0;
  cq_theta(&x, th);
  cq_theta(&b, th);
  x = x + 1;
  for (int i = 0; i < (b & 7); i++)
    cq_theta(&x, th);
  return cq_measure(x);
}
/* A quantum bound and a quantum exit (the cutoff at K): the carried garbage rail is rotated per trip. */
int p38_cutx(int x0, int b0, double th) {
  int x = x0, b = b0;
  cq_theta(&x, th);
  cq_theta(&b, th);
  x = x + 1;
  for (int i = 0; i < (b & 7); i++) {
    cq_theta(&x, th);
    if (x == 3)
      break;
  }
  return cq_measure(x);
}
