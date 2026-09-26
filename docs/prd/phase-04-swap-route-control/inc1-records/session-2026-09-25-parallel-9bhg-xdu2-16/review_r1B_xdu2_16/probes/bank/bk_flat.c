__attribute__((noinline)) static int slice(int k, int j) {
    int b[4];
    for (int x = 0; x < 4; ++x) b[x] = cq_theta(x, 0.25);
    int r = cq_theta(1, 0.5);
    int c = (b[k] > 1) & (r < 5);
    int w = cq_theta(b[j], 0.3);
    int t = c ? 1 : 55;
    return cq_measure(t) + cq_measure(w) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc, argc); }
