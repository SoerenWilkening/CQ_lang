/* The -O1 values of fptosi/fptoui from long double for selftest_f80.c, compiled WITHOUT FENV_ACCESS:
 * CR §2 takes the value from x86-64 LLVM 19 -O1 code (x87 fist/fisttp), not from strict code. */
#include <stdint.h>
#include <string.h>
#include "cqsf_roots.h"
/* bf16 <-> f80 (selftest_f80.c): the host's fpext bfloat to x86_fp80, and calls of the roots that take or
 * return __bf16 (the bits cross as integers; strict code would convert a __bf16 through float). */
long double hv_ext_bf16(uint16_t b) { __bf16 x; memcpy(&x, &b, 2); return (long double)x; }
long double lb80_ext_bf16(uint16_t b) { __bf16 x; memcpy(&x, &b, 2); return cqsf_fpext_bf16_to_f80(x); }
uint32_t lb80_ext_bf16_x(uint16_t b) { __bf16 x; memcpy(&x, &b, 2); return cqsf_fpext_bf16_to_f80_x(x); }
uint16_t lb80_trunc_bf16(long double x) { __bf16 r = cqsf_fptrunc_f80_to_bf16(x); uint16_t b; memcpy(&b, &r, 2); return b; }
uint16_t lb80_trunc_bf16_m(long double x, uint32_t m) { __bf16 r = cqsf_fptrunc_f80_to_bf16_m(x, m); uint16_t b; memcpy(&b, &r, 2); return b; }
uint32_t lb80_trunc_bf16_x(long double x, uint32_t m) { return cqsf_fptrunc_f80_to_bf16_x(x, m); }
void hv_fptoint_f80(long double x, uint64_t v[8]) {
    v[0] = (uint8_t)(int8_t)x; v[1] = (uint16_t)(int16_t)x; v[2] = (uint32_t)(int32_t)x; v[3] = (uint64_t)(int64_t)x;
    v[4] = (uint8_t)x; v[5] = (uint16_t)x; v[6] = (uint32_t)x; v[7] = (uint64_t)x;
}
