/* t22 — the Ry-stem angle select on a rail with RUN-TIME arms (the Inc-2b
   clearance narrowing: constant arms only). */
int slice(double a, double c) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    r = cq_theta(r, b ? a : c);
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(0.9, 0.3); return 0; }
