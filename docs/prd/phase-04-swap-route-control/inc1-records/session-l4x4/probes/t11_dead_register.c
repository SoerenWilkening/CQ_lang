/* t11 — the condition register b is DEAD after the region (never measured). */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
