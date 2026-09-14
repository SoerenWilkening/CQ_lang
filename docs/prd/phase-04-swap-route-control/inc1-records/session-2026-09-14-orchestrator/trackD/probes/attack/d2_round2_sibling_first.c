/* d2 — the DELTA-SCOPE attack, shape 2: the staler runs FIRST, so the staler's
   OWN read of the round-2 rail is harmless (nothing had moved the wire yet) and
   it is therefore NOT itself a decline. The later reader `b` is the stale one.
   If the delta scope has a hole this is where it would be — except that `b`'s
   operand IS the round-2 rail, so `b` is in the delta too. */
int ext_f(int a);
int slice(void){
  int q = cq_theta(0, 0.5);
  int y = 5; if (q > 5) y = ext_f(7);
  int keep = cq_measure(y);
  int x = (y != 0);
  int s  = cq_theta(x, 0.3);        /* FIRST: harmless read of x */
  int b  = cq_theta(x, 0.25);       /* SECOND: reads x after s moved it — STALE */
  return cq_measure(s) + cq_measure(b) + keep;
}
int main(void){ return slice(); }
