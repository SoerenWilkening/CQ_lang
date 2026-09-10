/* m01 — AREA 1: the rail is the condition AND the TRUE ARM (round-2 window,
   sibling BEFORE the select). `materializeCopySource`'s read of the rail as
   DATA is not one of the four recorded sites. */
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);
    bool c  = b ? 1 : b;          /* rail is condition and arm */
    return cq_measure(c) + cq_measure(b3) + keep;
}
int main(void) { (void) slice(); return 0; }
