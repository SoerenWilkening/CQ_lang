/* t19 — an if/else rotating TWO DIFFERENT registers (R3: one base). */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    int s = 9;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    s = cq_theta(s, 0.35);
    if (b) { r = cq_theta(r, 0.9); } else { s = cq_theta(s, 0.3); }
    return (int) cq_measure(b) + cq_measure(r) + cq_measure(s);
}
int main(void) { (void) slice(); return 0; }
