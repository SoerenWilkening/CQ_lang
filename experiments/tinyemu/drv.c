/* drv.c: a program linked against the lowered TinyEMU libraries (build_lib.sh): one softfp addition on a quantum
 * operand, as in spot.c, but calling the library's clone instead of lowering softfp.c from source. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include "softfp.h"
int main(void) {
    uint8_t q = 0;
    cq_theta(&q, 0.5);
    sfloat64 a = ((uint64_t)(1019 + (q >> 4)) << 52) | ((uint64_t)(q & 15) << 48);
    uint32_t fl = 0;
    sfloat64 r = add_sf64(a, 0x3ff0000000000000ull, RM_RNE, &fl);
    return (int)cq_measure((r >> 44) ^ fl);
}
