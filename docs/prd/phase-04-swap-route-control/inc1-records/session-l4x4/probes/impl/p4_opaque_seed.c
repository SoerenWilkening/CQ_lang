/* p4 — a rail whose classical seed is an opaque run-time value (the
   single-TU analogue of the H-2 window's `x`, but with `x` classical for
   good). Must ACCEPT and control on the rail. */
int slice(int y) {
    _Bool x = (y != 0);
    _Bool b = cq_theta(x, 0.25);
    int r = 7;
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(3); return 0; }
