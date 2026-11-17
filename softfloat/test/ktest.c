/* ktest.c: the loop cutoff K of the frem roots. fmod(x, y) with the largest exponent difference of each
 * format (x the largest finite, y the smallest subnormal, and two neighbours), through the lowered table
 * clone at each K, against the native root. Prints the smallest K that is right on every input; the
 * shims pass K_FREM (gen/gen_cqsf.py), which must be at least that. Built by test/run_ktest.sh. */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef unsigned __int128 u128;
u128 toy_val(int32_t h);
void cqrt_free(int32_t h);
int32_t cqrt_alloc_f16(_Float16); int32_t cqrt_alloc_f32(float); int32_t cqrt_alloc_f64(double);
int32_t __cq_q_cqsf_frem_f16_11_t(int32_t, int32_t, int32_t); void __cq_q_cqsf_frem_f16_11_t_unc(int32_t, int32_t, int32_t, int32_t);
int32_t __cq_q_cqsf_frem_f32_11_t(int32_t, int32_t, int32_t); void __cq_q_cqsf_frem_f32_11_t_unc(int32_t, int32_t, int32_t, int32_t);
int32_t __cq_q_cqsf_frem_f64_11_t(int32_t, int32_t, int32_t); void __cq_q_cqsf_frem_f64_11_t_unc(int32_t, int32_t, int32_t, int32_t);
uint16_t cqsfi_frem_f16(uint16_t, uint16_t); uint32_t cqsfi_frem_f32(uint32_t, uint32_t); uint64_t cqsfi_frem_f64(uint64_t, uint64_t);

#define KT(W, T, U, MAXF, CLONE, ROOT, KMAX)                                                             \
static int kt_##W(void) {                                                                              \
    U xs[] = {MAXF, MAXF - 1, MAXF - 7}, ys[] = {1, 3, 5};                                             \
    int kmin = -1;                                                                                     \
    for (int k = KMAX; k >= 1; k--) {                                                                  \
        int ok = 1;                                                                                    \
        for (int i = 0; i < 3; i++) for (int j = 0; j < 3; j++) {                                      \
            T x, y; memcpy(&x, &xs[i], sizeof x); memcpy(&y, &ys[j], sizeof y);                        \
            int32_t a = cqrt_alloc_##W(x), b = cqrt_alloc_##W(y);                                      \
            int32_t r = CLONE(a, b, k);                                                                \
            if ((U)toy_val(r) != ROOT(xs[i], ys[j])) ok = 0;                                            \
            CLONE##_unc(r, a, b, k);                                                                   \
            cqrt_free(b); cqrt_free(a);                                                                \
        }                                                                                              \
        if (!ok) break;                                                                                \
        kmin = k;                                                                                      \
    }                                                                                                  \
    printf("frem_" #W ": smallest K right on the worst cases = %d (shims pass %d)\n", kmin, KMAX);       \
    return kmin;                                                                                       \
}
KT(f16, _Float16, uint16_t, 0x7BFF, __cq_q_cqsf_frem_f16_11_t, cqsfi_frem_f16, 8)
KT(f32, float, uint32_t, 0x7F7FFFFF, __cq_q_cqsf_frem_f32_11_t, cqsfi_frem_f32, 16)
KT(f64, double, uint64_t, 0x7FEFFFFFFFFFFFFFull, __cq_q_cqsf_frem_f64_11_t, cqsfi_frem_f64, 80)

int main(void) {
    int a = kt_f16(), b = kt_f32(), c = kt_f64();
    return (a < 1 || b < 1 || c < 1) ? 1 : 0;
}
