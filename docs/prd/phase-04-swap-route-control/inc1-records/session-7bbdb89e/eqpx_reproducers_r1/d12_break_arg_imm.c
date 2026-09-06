__attribute__((noinline))
int run(int seed, int n, int m) {
    int q = cq_theta(seed, 0.25);
    for (int i = 0; i < n; i++) { q = q ^ m; if ((q & 1) == 0) break; }
    return cq_measure(q);
}
int main(void){ (void)run(3,4,5); return 0; }
