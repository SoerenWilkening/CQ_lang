// ⚠ MEASURED-INVALID CONTROL, corrected at the site rather than left to a reader
// (CLAUDE.md L7-with-a-twist). Adding a SECOND arm that rewrites `r` made `r` a
// multi-armed loop-carried tainted value, so this DECLINES on the COMBINED binary
// `07d937842bfb5135` with `cq loop lowering: loop-carried tainted value crosses
// iterations` — a different fence entirely. It does NOT isolate multi-exit.
// The control that DOES is x9_break_with_p2_discharged_rail.c (single exit, taken
// break, rail discharged once). Kept, not deleted: the decline is itself the
// record of why this spelling cannot be the control.
// ISOLATING CONTROL for x1: the SAME program with the second exit removed, i.e.
// `dD1` at K=4. One exit block => P2's anchor fires => the rail is discharged.
// If x1 leaks and x1c does not, the discriminant is MULTI-EXIT and nothing else.
#include <CQ.h>
int main(void) {
  volatile int lim_v = 2;
  int lim = lim_v;
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 4; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
    if (i == lim) r = cq_theta(r, 0.1);   /* same extra branch, NO exit */
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}
