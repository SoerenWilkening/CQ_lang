__attribute__((noinline)) static int chain(int n, int a) {
    if (n <= 0) return a;
    return a - chain(n - 1, a + 1);           /* non-associative use of the result: not loop-convertible */
}
int quantum_depth_recursion(int n0, double th, int a) {
    int n = n0;
    cq_theta(&n, th);
    return cq_measure(chain(n & 3, a));      /* the recursion depth is quantum */
}
