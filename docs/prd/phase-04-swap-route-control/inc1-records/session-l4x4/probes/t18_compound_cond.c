/* t18 — the rail as a NON-ROOT leaf of a compound condition tree. */
int slice(void) {
    _Bool b = 0;
    int q = 3;
    int r = 7;
    b = cq_theta(b, 0.5);
    q = cq_theta(q, 0.2);
    r = cq_theta(r, 0.25);
    if (b && q > 5) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
