int ext_f(int a);
__attribute__((noinline))
int run(int seed, int pseed, int n) {
    int p = cq_theta(pseed, 0.5);
    int y = 5; if (p > 5) y = ext_f(7);
    int w = y & 7;
    int q = cq_theta(seed, 0.25);
    for (int i = 0; i < n; i++) { q = q ^ w; if ((q & w) == 0) break; }
    return cq_measure(q) + cq_measure(y);
}
int main(void){ (void)run(3,7,4); return 0; }
