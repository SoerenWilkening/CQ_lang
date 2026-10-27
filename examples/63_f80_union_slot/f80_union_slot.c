/* openlibm ld80 idiom: union IEEEl2bits. The 16-byte bit-field struct overlaps the 10-byte long double, so SROA cannot
 * split the union and it stays an alloca at -O1: a store x86_fp80, loads/stores of i64 words at byte offsets, load x86_fp80. */
union ieee_l2bits { long double e; struct { unsigned manl : 32; unsigned manh : 32; unsigned exp : 15; unsigned sign : 1; unsigned junk : 16; } bits; };
long double f80_union_slot(long double x0, double th, int k) {
    long double x = x0;
    cq_theta(&x, th);
    union ieee_l2bits u;
    u.e = x;                               /* store x86_fp80 into the union slot */
    int e = (int)u.bits.exp - k;           /* read the exponent bit-field (word at byte 8) */
    u.bits.exp = (unsigned)e & 0x7fff;     /* write it back: read-modify-write of that word */
    return cq_measure(u.e);                /* read the long double view again */
}
