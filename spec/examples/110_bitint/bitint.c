__attribute__((noinline)) static _BitInt(7) bump7(_BitInt(7) s, _BitInt(7) k) { return s + k; }
unsigned long bitint_u100(unsigned long x0, double th, unsigned long c) {
    unsigned long x = x0;
    cq_theta(&x, th);
    unsigned _BitInt(100) a = x;
    a = a * c + (a >> 7);
    return cq_measure((unsigned long)(a >> 36));
}
int bitint_s7(unsigned long x0, double th, int k) {
    unsigned long x = x0;
    cq_theta(&x, th);
    _BitInt(7) s = bump7((_BitInt(7))x, (_BitInt(7))k);
    return cq_measure((int)s);
}
