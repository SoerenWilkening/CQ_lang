/* slice_libm_real_fdimf.c — bd 3c6m.58: the REAL openlibm fdimf body
   (src/s_fdim.c DECL macro + src/s_isnan.c __isnanf, fdlibm-derived,
   BSD-licensed) over f32. f32 sibling of fdim.f64 / fdiml.f80: the
   union IEEEf2bits is SROA-promoted by clang -O1 to a register
   `bitcast float to i32`, so the slice lands on the plain integer-extraction
   template surface at width 32. As in the f64 sibling, no lshr/trunc survives —
   InstCombine folds each bitfield test into a masked compare against a
   pre-shifted constant (`and i32` + `icmp` only). Here that is doubly true: the
   f32 mantissa field sits at bit 0, so __isnanf's `u.bits.man != 0` needs no
   shift even before InstCombine.

   Note openlibm's isnan() macro dispatches on sizeof: a float argument selects
   __isnanf, whose test is a SINGLE 23-bit mantissa field (`u.bits.man != 0`),
   not the manl/manh pair of the f64/f80 bodies.

   The probe pins the census cell fdimf.f32: x = theta-tainted, y = 0.5f
   (classical), so isnan(y) const-folds exactly as in the census IR. */

/* The exact fpmath.h little-endian f32 bit-pattern union (openlibm src/fpmath.h). */
union IEEEf2bits {
    float f;
    struct {
        unsigned int man  : 23;
        unsigned int exp  : 8;
        unsigned int sign : 1;
    } bits;
};

/* openlibm s_isnan.c __isnanf (verbatim). */
__attribute__((always_inline)) static inline int olm_isnanf(float f) {
    union IEEEf2bits u;

    u.f = f;
    return (u.bits.exp == 255 && u.bits.man != 0);
}

/* openlibm s_fdim.c DECL(float, fdimf) (verbatim). */
__attribute__((always_inline)) static inline float olm_fdimf(float x, float y) {

    if (olm_isnanf(x))
        return (x);
    if (olm_isnanf(y))
        return (y);
    return (x > y ? x - y : 0.0);
}

float slice(void) {
    float q = cq_theta_f32(0.5f, 0.5);
    return cq_measure_f32(olm_fdimf(q, 0.5f));
}

int main(void) {
    (void) slice();
    return 0;
}
