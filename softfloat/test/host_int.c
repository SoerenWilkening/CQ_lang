/* The host's -O1 values of the INT_X conversions for selftest_int.c, compiled WITHOUT FENV_ACCESS: CR §2
 * takes the value from x86-64 LLVM 19 -O1 code (cvtt, fist, compiler-rt __floattisf, __fixdfti and the like, and
 * ExpandLargeFpConvert above 128 bits). Operands and results cross as bytes. Each returns 1, or 0 where
 * the host cannot compute the value: LLVM 19's compiler-rt for x86 macOS has no __floattihf,
 * __floatuntihf, __fixhfti, __fixunshfti, so iN <-> f16 for 64 < N <= 128 does not link natively, and
 * f80 <-> iN above 128 bits needs fp128 libcalls (__trunctfxf2, __extendxftf2) macOS does not have. */
#include <stdint.h>
#include <string.h>

#define HI(N, T, TN)                                                                                    \
int hv_sitofp_i##N##_to_##TN(const void *i, void *o) { _BitInt(N) x; memcpy(&x, i, sizeof x); T r = (T)x; memcpy(o, &r, sizeof r); return 1; } \
int hv_uitofp_i##N##_to_##TN(const void *i, void *o) { unsigned _BitInt(N) x; memcpy(&x, i, sizeof x); T r = (T)x; memcpy(o, &r, sizeof r); return 1; } \
int hv_fptosi_##TN##_to_i##N(const void *i, void *o) { T x; memcpy(&x, i, sizeof x); _BitInt(N) r = (_BitInt(N))x; memcpy(o, &r, sizeof r); return 1; } \
int hv_fptoui_##TN##_to_i##N(const void *i, void *o) { T x; memcpy(&x, i, sizeof x); unsigned _BitInt(N) r = (unsigned _BitInt(N))x; memcpy(o, &r, sizeof r); return 1; }
#define HNONE(N, TN)                                                                                    \
int hv_sitofp_i##N##_to_##TN(const void *i, void *o) { (void)i; (void)o; return 0; }                    \
int hv_uitofp_i##N##_to_##TN(const void *i, void *o) { (void)i; (void)o; return 0; }                    \
int hv_fptosi_##TN##_to_i##N(const void *i, void *o) { (void)i; (void)o; return 0; }                    \
int hv_fptoui_##TN##_to_i##N(const void *i, void *o) { (void)i; (void)o; return 0; }
#define HALL(N) HI(N, __bf16, bf16) HI(N, float, f32) HI(N, double, f64)

HALL(7) HALL(24) HALL(48) HALL(100) HALL(128) HALL(200)
/* f80 <-> i200: the expansion goes through fp128 (__trunctfxf2, __extendxftf2), which macOS lacks */
HI(7, long double, f80) HI(24, long double, f80) HI(48, long double, f80) HI(100, long double, f80) HI(128, long double, f80)
HNONE(200, f80)
HI(7, _Float16, f16) HI(24, _Float16, f16) HI(48, _Float16, f16) HNONE(100, f16) HNONE(128, f16) HI(200, _Float16, f16)
