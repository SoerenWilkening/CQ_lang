/* d1 — the DELTA-SCOPE attack, shape 1: the stale reader's operand is tainted at
   ROUND 1 (a theta result), while its whole ancestry hangs off a value that is
   tainted only at ROUND 2 (the 6.5 arm's `%out`). The reader is therefore NOT in
   the delta, so the delta-scoped re-ask skips it — the question is whether the
   ROUND-1 pass already caught it. Here the staler `b3` is a FORWARD user of the
   reader's own operand, which the round-1 walk reaches with no taint-gated hop. */
int ext_f(int a);
int slice(void){
  int q = cq_theta(0, 0.5);
  int y = 5; if (q > 5) y = ext_f(7);
  int keep = cq_measure(y);
  int x = (y != 0);                 /* CLASSICAL at round 1, TAINTED at round 2 */
  int b  = cq_theta(x, 0.25);
  int b3 = cq_theta(b, 0.9);        /* CHAINED — well formed */
  return cq_measure(b) + cq_measure(b3) + keep;   /* measure(b) is MID-CHAIN: stale */
}
int main(void){ return slice(); }
