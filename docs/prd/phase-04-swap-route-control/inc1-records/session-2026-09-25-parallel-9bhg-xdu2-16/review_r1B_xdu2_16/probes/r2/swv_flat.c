__attribute__((noinline)) static int slice(int n, int k) {
    int q = cq_theta(0, 0.25);
    int u;
    switch (q) { case 1: u = k + 1; break; case 2: u = k * 3; break; case 5: u = k ^ 9; break; default: u = k; }
    return cq_measure(q) + cq_measure(u);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc + 4); }
