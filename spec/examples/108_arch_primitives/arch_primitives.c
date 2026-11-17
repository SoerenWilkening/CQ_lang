unsigned ctz_q(unsigned long long x0, double th) {
    unsigned long long x = x0;
    cq_theta(&x, th);
    return cq_measure((unsigned)__builtin_ctzll(x | 1ull << 32));   /* nonzero: the low 32 bits of x or bit 32 */
}
int trap_q(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k)
        __builtin_trap();
    return cq_measure(x + 1);
}
static __thread int tl;
__attribute__((noinline)) static void touch(int *p, int c) { *p += c; }   /* the thread-local's address in a call keeps it in memory at -O1 */
int tls_q(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    tl = x + 1;                                            /* a quantum value into the thread-local */
    touch(&tl, c);
    return cq_measure(tl * 2);
}
