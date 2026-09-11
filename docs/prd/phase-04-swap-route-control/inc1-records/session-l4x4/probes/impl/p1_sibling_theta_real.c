/* p1 — the REAL F-1b-1 class: two in-place Ry on ONE physical rail (the seed
   is TAINTED, so -O1 cannot const-fold the siblings apart the way it does in
   t10), the branch reading the stale name. Must DECLINE at rung (iii). */
int slice(int q0) {
    int q = cq_theta(q0, 0.2);
    _Bool t = (_Bool)(q & 1);
    int r = 7;
    _Bool b = cq_theta(t, 0.5);
    _Bool c = cq_theta(t, 0.9);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + (int) cq_measure(c) + cq_measure(r);
}
int main(void) { (void) slice(3); return 0; }
