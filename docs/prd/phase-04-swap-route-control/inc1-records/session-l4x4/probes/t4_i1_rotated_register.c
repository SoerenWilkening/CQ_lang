/* t4 — shape (4): an i1 ROTATED register under an i1 condition. Two
   separate rails, both _Bool. */
int slice(void) {
    _Bool b = 0;
    _Bool r = 0;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + (int) cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
