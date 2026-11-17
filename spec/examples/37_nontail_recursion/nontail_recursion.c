__attribute__((noinline)) static int sumdown(unsigned x, unsigned k, unsigned a) {
    if (x <= k)
        return x;
    return x + sumdown(x / a, k, a);
}
int nontail_recursion(unsigned x0, double th, unsigned k, unsigned a) {
    unsigned x = x0;
    cq_theta(&x, th);
    return cq_measure(sumdown(x, k, a));
}
