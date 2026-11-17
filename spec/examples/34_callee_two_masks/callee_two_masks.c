__attribute__((noinline)) static int mix(int a, int b) { return a * 3 + b; }
int callee_two_masks(int x0, int y0, double tx, double ty, int c) {
    int x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    int r1 = mix(x, c);
    int r2 = mix(c, y);
    int r3 = mix(x, y);
    return cq_measure(r1 + r2 + r3);
}
