/* t10 — shape (10): a SIBLING theta on b's rail before the branch
   (the F-1b-1 class: two in-place Ry on ONE rail, the branch reading
   the stale name). */
int slice(void) {
    _Bool t = 0;
    int r = 7;
    _Bool b = cq_theta(t, 0.5);
    _Bool c = cq_theta(t, 0.9);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + (int) cq_measure(c) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
