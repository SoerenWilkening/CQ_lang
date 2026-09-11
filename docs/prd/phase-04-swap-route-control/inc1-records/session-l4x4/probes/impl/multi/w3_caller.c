/* w3 — the RUNG (ii) half of the round-2 taint window: the `%out`-derived
   PARENT of the condition rail is MEASURED before the branch. At round-1 taint
   `x` is classical, so `railWireNamesBackward` stops at `b` and never sees the
   measure; at FINAL taint `b` is CHAINED onto `x`'s rail and the measurement
   collapses the very register the arm controls on. */
int ext_f(int a);
void ext_sink(int a);
int slice(int g) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    if (g) ext_sink(keep);
    _Bool x = (y != 0);
    _Bool xm = cq_measure(x);
    _Bool b  = cq_theta(x, 0.25);
    int r = 7;
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return cq_measure(r) + (int) xm + keep;
}
int main(void) { (void) slice(1); return 0; }
