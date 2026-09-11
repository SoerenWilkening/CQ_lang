/* r03 — b ALSO read as DATA after the region (zext into an int), that int measured. */
int slice(void) {
    _Bool b = 0; int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    int z = (int) b + 1;
    return cq_measure(r) + cq_measure(z);
}
int main(void) { (void) slice(); return 0; }
