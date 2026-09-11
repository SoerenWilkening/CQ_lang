/* t6 — shape (6): the Ry ON the condition's OWN wire. MUST keep declining. */
int slice(void) {
    _Bool b = 0;
    b = cq_theta(b, 0.5);
    if (b) { b = cq_theta(b, 0.9); }
    return (int) cq_measure(b);
}
int main(void) { (void) slice(); return 0; }
