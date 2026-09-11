/* t2 — shape (2): the if/else twin. clang -O1 folds this to ONE cq_theta
   call with a tainted-condition ANGLE select (drbq Inc 2b, PRD §12.3). */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); } else { r = cq_theta(r, 0.3); }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
