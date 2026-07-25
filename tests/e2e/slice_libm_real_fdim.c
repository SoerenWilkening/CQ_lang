/* slice_libm_real_fdim.c — bd 3c6m.58: the REAL openlibm fdim body
   (src/s_fdim.c DECL macro + src/s_isnan.c `(isnan)(double)`, fdlibm-derived,
   BSD-licensed) over f64. This is the f64 sibling of the verified fdiml.f80
   slice: where the fp80 body needs the promoteFp80Union peephole (its offset-8
   exponent word straddles the undefined padding of the 80-bit value), the f64
   union IEEEd2bits is SROA-promoted by clang -O1 to a register
   `bitcast double to i64`, so the slice lands on the plain integer-extraction
   template surface. NB the bitfield reads do NOT survive as lshr/trunc: SROA's
   immediate output has them, but InstCombine folds each field test into a single
   masked compare against a pre-shifted constant, so the -O1 IR (and the golden)
   carry only `and i64` + `icmp` — `cq_template_and_i64_hl` /
   `cq_template_icmp_{ne,eq}_i64_hl`, with no lshr, trunc or zext anywhere.

   The probe pins the census cell fdim.f64: x = theta-tainted, y = 0.5
   (classical), so isnan(y) const-folds exactly as in the census IR. */

/* The exact fpmath.h little-endian f64 bit-pattern union (openlibm src/fpmath.h,
   __BYTE_ORDER__/__FLOAT_WORD_ORDER__ both little-endian on x86-64). */
union IEEEd2bits {
    double d;
    struct {
        unsigned int manl : 32;
        unsigned int manh : 20;
        unsigned int exp  : 11;
        unsigned int sign : 1;
    } bits;
};

/* openlibm s_isnan.c (isnan)(double) (verbatim). */
__attribute__((always_inline)) static inline int olm_isnan(double d) {
    union IEEEd2bits u;

    u.d = d;
    return (u.bits.exp == 2047 && (u.bits.manl != 0 || u.bits.manh != 0));
}

/* openlibm s_fdim.c DECL(double, fdim) (verbatim). */
__attribute__((always_inline)) static inline double olm_fdim(double x, double y) {

    if (olm_isnan(x))
        return (x);
    if (olm_isnan(y))
        return (y);
    return (x > y ? x - y : 0.0);
}

double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(olm_fdim(q, 0.5));
}

int main(void) {
    (void) slice();
    return 0;
}
