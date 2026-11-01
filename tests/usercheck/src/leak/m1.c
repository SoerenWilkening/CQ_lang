__attribute__((noinline)) static void bump(int *p) { *p += 1; }
int m1(int x0, double th, int k, int a0, double ta, int b0, double tb) {
    int x = x0, a = a0, b = b0;
    cq_theta(&x, th);
    cq_theta(&a, ta);
    cq_theta(&b, tb);
    int s = a * 5 + b;
    int *p = (x > k) ? &a : &b;
    int t = *p;
    *p = t + 7;
    bump(p);
    int u = t * 3 + s;
    return cq_measure(a) + cq_measure(b) + cq_measure(u);
}
