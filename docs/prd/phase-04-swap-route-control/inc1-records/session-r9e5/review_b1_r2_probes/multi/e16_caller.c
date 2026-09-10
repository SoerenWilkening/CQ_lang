/* e16 — the RAIL spelling of the round-2 taint window in PLAIN C (two TUs).
   `y` is kept live as an i32 (it is also measured) so `-O1` cannot sink the
   `!= 0` into the arms; the merge stays the 6.5 classical-call-arm `%out`. */
int ext_f(int a);
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);
    int a = b ? 2 : 5;
    return cq_measure(a) + cq_measure(b3) + keep;
}
int main(void) { (void) slice(); return 0; }
