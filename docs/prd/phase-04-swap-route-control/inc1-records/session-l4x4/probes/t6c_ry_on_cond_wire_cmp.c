/* t6c — t6's COMPARE twin: the arm rotates the condition register. */
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    if (q == 5) { q = cq_theta(q, 0.9); }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
