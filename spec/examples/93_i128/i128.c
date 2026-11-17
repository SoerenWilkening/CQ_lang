unsigned long long mul_i128(unsigned long long x0, double th, unsigned long long c) {
    unsigned long long x = x0;
    cq_theta(&x, th);
    unsigned __int128 p = (unsigned __int128)x * c;    /* widening multiply: i128 mul */
    unsigned __int128 q = p + ((unsigned __int128)c << 64);
    return cq_measure((unsigned long long)(q >> 64));
}
unsigned long long div_i128(unsigned long long x0, double th, unsigned long long hi, unsigned long long lo) {
    unsigned long long x = x0;
    cq_theta(&x, th);
    unsigned __int128 n = ((unsigned __int128)hi << 64) | lo;
    unsigned __int128 d = (unsigned __int128)x | ((unsigned __int128)1 << 64);
    return cq_measure((unsigned long long)(n / d));     /* __udivti3 */
}
