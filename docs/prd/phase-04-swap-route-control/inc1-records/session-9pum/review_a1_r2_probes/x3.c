int slice(void) {
    int q = 0; q = cq_theta(q, 0.5);
    int m = cq_measure(q);
    q = q ^ 9;
    int a = (q > 5) ? 2 : 5;
    return m + a + cq_measure(q);
}
int main(void){ (void) slice(); return 0; }
