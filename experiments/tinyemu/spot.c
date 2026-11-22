/* spot.c: §6 spot checks of lowered TinyEMU code (cqcc --cq-check, with src/softfp.c as a second input). Each entry
 * takes its classical arguments from the checker and 8 quantum bits from cq_theta, calls one TinyEMU function and
 * measures the result and the exception flags. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include "softfp.h"

/* add_sf64: a quantum operand 1.xxxx * 2^(e-4), x and e from the quantum byte, plus a classical operand */
uint64_t spot_add64(uint64_t b, uint8_t rm) {
    uint8_t q = 0;
    cq_theta(&q, 0.5);
    sfloat64 a = ((uint64_t)(1019 + (q >> 4)) << 52) | ((uint64_t)(q & 15) << 48);
    uint32_t fl = 0;
    sfloat64 r = add_sf64(a, b, (RoundingModeEnum)(rm % 5), &fl);
    return cq_measure(r ^ ((uint64_t)fl << 59));
}

/* mul_sf32: the quantum byte as the top bits of one operand (sign, exponent, mantissa) */
uint32_t spot_mul32(uint32_t b) {
    uint8_t q = 0;
    cq_theta(&q, 0.5);
    sfloat32 a = ((uint32_t)q << 24) | 0x00400000u;
    uint32_t fl = 0;
    sfloat32 r = mul_sf32(a, b, RM_RNE, &fl);
    return cq_measure(r ^ (fl << 27));
}

/* sqrt_sf32: every 8-bit pattern in the exponent and top mantissa bits, negatives and NaNs included */
uint32_t spot_sqrt32(uint32_t lo) {
    uint8_t q = 0;
    cq_theta(&q, 0.5);
    sfloat32 a = ((uint32_t)q << 23) | (lo & 0x7fffff);
    uint32_t fl = 0;
    sfloat32 r = sqrt_sf32(a, RM_RNE, &fl);
    return cq_measure(r ^ (fl << 27));
}
