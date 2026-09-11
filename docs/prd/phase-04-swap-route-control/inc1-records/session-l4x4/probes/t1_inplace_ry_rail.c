/* t1 — 1b-C shape (1): in-place Ry arm on a register DISJOINT from the
   bare _Bool condition. The compare twin (t1c) is the shipped drbq Inc-1
   flagship slice. */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
