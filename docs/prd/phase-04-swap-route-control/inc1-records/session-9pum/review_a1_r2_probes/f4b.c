int slice(int u) {
    int q = cq_theta(u, 0.5);
    long long t = (long long) q;
    long long m = cq_measure(q);
    int a = (t == 5) ? 2 : 5;
    return (int)(m + a + cq_measure(t));
}
int main(void){ (void) slice(2); return 0; }
