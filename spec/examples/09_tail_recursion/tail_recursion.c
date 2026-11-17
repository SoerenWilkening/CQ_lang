__attribute__((noinline)) static int count(unsigned x, int n, unsigned k, unsigned a, unsigned b) {
    if (x > k)
        return count(x * a + b, n + 1, k, a, b);
    return n;
}

int tail_recursion(unsigned x0, double th, unsigned k, unsigned a, unsigned b) {
    unsigned x = x0;
    cq_theta(&x, th);
    return cq_measure(count(x, 0, k, a, b));
}
