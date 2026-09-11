/* t24 — R6: a PRE-region SSA record of the rotated register read AFTER the
   region (`mark` names the pre-Ry value). */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    int mark = r;
    if (b) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + cq_measure(r) + cq_measure(mark);
}
int main(void) { (void) slice(); return 0; }
