/* t3 — shape (3): controlled STATE PREP (drbq Inc 4) on a rail condition.
   The seed is an i32 constant, so F2's i1-collision is NOT the question
   here; measure whether F2 is reached at all. */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    if (b) { r = cq_theta(7, 0.9); }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
