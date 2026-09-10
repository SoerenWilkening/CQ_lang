/* m03 — AREA 1: a controlled RETURN (7.2 AbortParkEmit) under a bare rail
   condition in the round-2 window. */
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);
    if (b) return 7 + keep;
    return cq_measure(b3) + keep;
}
int main(void) { (void) slice(); return 0; }
