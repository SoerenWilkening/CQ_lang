__attribute__((noinline)) static int odd_step(int x, int n, int k);
__attribute__((noinline)) static int even_step(int x, int n, int k) {
    if (n <= 0)
        return x;
    return odd_step(x + 3, n - 1, k) - k;     /* f calls g; the result is used, so not a tail call */
}
__attribute__((noinline)) static int odd_step(int x, int n, int k) {
    if (n <= 0)
        return x;
    if (x > k)                                /* quantum branch inside one of the pair: a phase arm */
        cq_phi(0.25);
    return even_step(x - 1, n - 1, k) + 1;    /* g calls f */
}
int mutual_recursion(int x0, double th, int n, int k) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(even_step(x, n, k));     /* recursion depth n is classical */
}
