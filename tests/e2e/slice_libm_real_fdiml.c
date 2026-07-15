/* slice_libm_real_fdiml.c — bd 3c6m.51 Inc 1: the REAL openlibm fdiml body
   (s_fdim.c DECL macro + s_isnan.c __isnanl, fdlibm-derived, BSD-licensed) over
   x86_fp80 `long double`. This is the FIRST long-double libm slice: unlike the
   f64/f32 siblings (fdim.f64 compiles because clang -O1 SROA-promotes their union
   to a register `bitcast double to i64`), the fp80 body routes isnan through a
   `union IEEEl2bits` bit-pattern type-pun whose offset-8 exponent word straddles
   the undefined padding bytes [10,16) of the 80-bit value in its 16-byte slot —
   so SROA CANNOT promote it and the union stays in MEMORY past clang -O1.

   The promoteFp80Union peephole (bd 3c6m.51) rewrites the union to
   `bitcast x86_fp80 -> i80` + lshr/trunc/zext register form (padding modelled as
   0, sound under the mask fence), the classical isnan(0.5L) union folds to a dead
   branch, and PredMux flattens the residual tainted isnan(x)/exponent control to
   the shipped select substrate. This slice is the LINK-layer proof (Rule 2) that
   every emitted i80/f80 symbol resolves and the trace is stable.

   The probe pins the census cell fdiml.f80: x = theta-tainted, y = 0.5L
   (classical), so isnan(y) const-folds exactly as in the census IR. */

/* The exact amd64 x86_fp80 bit-pattern union (openlibm amd64_fpmath.h). */
union IEEEl2bits {
    long double e;
    struct {
        unsigned int manl : 32;
        unsigned int manh : 32;
        unsigned int exp  : 15;
        unsigned int sign : 1;
        unsigned int junkl : 16;
        unsigned int junkh : 32;
    } bits;
};
#define LDBL_NBIT 0x80000000
#define mask_nbit_l(u) ((u).bits.manh &= ~LDBL_NBIT)

/* openlibm s_isnan.c __isnanl (verbatim). */
__attribute__((always_inline)) static inline int olm_isnanl(long double e) {
    union IEEEl2bits u;
    u.e = e;
    mask_nbit_l(u);
    return (u.bits.exp == 32767 && (u.bits.manl != 0 || u.bits.manh != 0));
}

/* openlibm s_fdim.c DECL(long double, fdiml) (verbatim). */
__attribute__((always_inline)) static inline long double olm_fdiml(long double x,
                                                                   long double y) {
    if (olm_isnanl(x))
        return x;
    if (olm_isnanl(y))
        return y;
    return (x > y ? x - y : 0.0L);
}

long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(olm_fdiml(q, 0.5L));
}

int main(void) {
    (void) slice();
    return 0;
}
