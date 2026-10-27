__attribute__((noinline)) static int polyval(int x, const int *c, int n) {
    int s = c[0];
    for (int i = 1; i < n; i++)
        s = s * x + c[i];
    return s;
}
int callee_with_loop(int x0, double th, const int *c, int n) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(polyval(x, c, n));
}
