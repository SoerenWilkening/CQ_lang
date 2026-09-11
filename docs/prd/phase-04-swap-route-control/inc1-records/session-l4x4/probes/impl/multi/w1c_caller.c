/* w1 — H-2 at the in-place Ry arm: the ROUND-2 TAINT WINDOW. `x` is CLASSICAL
   at round 1 (it reads the 6.5 classical-call arm's `%out`), so the rail ladder
   sees `b` and `b3` as two SOURCE thetas; `repropagateControlMerges` then makes
   `x` tainted and `lowerRotations` lowers both CHAINED onto ONE rail. */
int ext_f(int a);
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    _Bool x = (y != 0);
    int bq = cq_theta((int) x, 0);
    int b  = cq_theta(bq, 0.25);
    int b3 = cq_theta((int) x, 0.9);
    int r = 7;
    r = cq_theta(r, 0.25);
    if (b > 0) { r = cq_theta(r, 0.9); }
    return cq_measure(r) + cq_measure(b3) + keep;
}
int main(void) { (void) slice(); return 0; }
