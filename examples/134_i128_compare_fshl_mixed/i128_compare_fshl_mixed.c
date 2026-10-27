unsigned long long i128_compare_merge(unsigned long long x0, double th, unsigned long long c, unsigned long long lim) {
    unsigned long long x = x0;
    cq_theta(&x, th);
    unsigned __int128 p = (unsigned __int128)x * c;
    unsigned __int128 r;
    if (p > ((unsigned __int128)lim << 64))  /* i128 compare as a quantum condition */
        r = p >> 1;
    else
        r = p + 1;                           /* i128 merge under it */
    return cq_measure((unsigned long long)(r >> 64));
}
unsigned fshl_mixed(unsigned x0, double th, unsigned c) {
    unsigned x = x0;
    cq_theta(&x, th);
    return cq_measure((x << 3) | (c >> 29));  /* fshl(x, c, 3): a quantum and a classical data operand */
}
