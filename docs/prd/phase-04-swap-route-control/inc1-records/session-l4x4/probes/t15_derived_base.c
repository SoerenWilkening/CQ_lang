/* t15 — DERIVED rotated base (`r = p * 5`) under a rail condition: the
   Inc-1 round-1 structural-freeze shape. */
int slice(void) {
    _Bool b = 0;
    int p = 3;
    b = cq_theta(b, 0.5);
    p = cq_theta(p, 0.25);
    int r = p * 5;
    if (b) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
