/* e12 — PLAIN C, TWO TUs (the shipped 6.5 recipe): the round-2 taint window with
   a rail-conditioned data select. `y` is the classical-call-arm `%out`, classical
   at round 1 and tainted at round 2; `b` and `b3` then ride ONE rail and the
   select controls on the LATER one. */
int ext_f(int a);
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    bool x = (bool) y;
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);
    int a = b ? 2 : 5;
    return cq_measure(a) + cq_measure(b3);
}
int main(void) { (void) slice(); return 0; }
