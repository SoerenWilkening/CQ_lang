/* The -O1 values of fptosi/fptoui from long double for selftest_f80.c, compiled WITHOUT FENV_ACCESS:
 * CR §2 takes the value from x86-64 LLVM 19 -O1 code (x87 fist/fisttp), not from strict code. */
#include <stdint.h>
void hv_fptoint_f80(long double x, uint64_t v[8]) {
    v[0] = (uint8_t)(int8_t)x; v[1] = (uint16_t)(int16_t)x; v[2] = (uint32_t)(int32_t)x; v[3] = (uint64_t)(int64_t)x;
    v[4] = (uint8_t)x; v[5] = (uint16_t)x; v[6] = (uint32_t)x; v[7] = (uint64_t)x;
}
