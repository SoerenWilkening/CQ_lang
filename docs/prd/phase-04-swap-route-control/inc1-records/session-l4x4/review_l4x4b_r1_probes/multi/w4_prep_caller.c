/* w4 — the ROUND-2 TAINT WINDOW through the controlled STATE PREP (not the
   in-place arm): `x` is classical at round 1, tainted at round 2, so `b` and
   `b3` are two SOURCE thetas to the ladder and ONE rail to the lowering. */
int ext_f(int a);
void ext_sink(int a);
int slice(int g) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    if (g) ext_sink(keep);
    _Bool x = (y != 0);
    _Bool b  = cq_theta(x, 0.25);
    _Bool b3 = cq_theta(x, 0.9);
    int r = 7;
    if (b) { r = cq_theta(7, 0.9); }
    return cq_measure(r) + (int) cq_measure(b3) + keep;
}
int main(void) { (void) slice(1); return 0; }
