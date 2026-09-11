int slice(int u) {
    int q = cq_theta(u, 0.5);
    int r = cq_theta(u + 1, 0.25);
    int m = cq_measure(q);
    int a = (q == r) ? 2 : 5;
    return m + a + cq_measure(r);
}
int main(void){ (void) slice(2); return 0; }
