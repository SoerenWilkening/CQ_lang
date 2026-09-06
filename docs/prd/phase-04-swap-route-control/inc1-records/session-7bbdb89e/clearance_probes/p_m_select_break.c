/* clearance probe M: a 4.4 select-merge immediate (tainted at ROUND 1) inside a W1 break loop */
__attribute__((noinline))
int run(int seed, int pseed, int n) {
    int p = cq_theta(pseed, 0.5);
    int y = (p > 5) ? 7 : 5;
    int w = y & 7;
    int q = cq_theta(seed, 0.25);
    for (int i = 0; i < n; i++) { q = q ^ w; if ((q & 1) == 0) break; }
    return cq_measure(q) + cq_measure(y);
}
int main(void){ (void)run(3,7,4); return 0; }
