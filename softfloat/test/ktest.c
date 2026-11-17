/* ktest.c: the loop cutoff K of the frem roots. fmod(x, y) with the largest exponent difference of each
 * format (x the largest finite, y the smallest subnormal, and two neighbours), through the lowered table
 * clone at each K, against the native root. Prints the smallest K that is right on every input; the
 * shims pass K_FREM (gen/gen_cqsf.py), which must be at least that. Built by test/run_ktest.sh
 * (f80 with `run_ktest.sh f80`: needs build/libqsoftfloat_f80.a; a binary search over K, the cost of
 * one call grows with K). */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
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

#ifdef KT_F80
/* f80: x the largest finite (exponent 0x7FFE) and two neighbours, y the smallest subnormal and two
 * neighbours: exponent difference 32,766 - (-62) = 32,828, 1,131 trips of the 29-bit loop. Right at K
 * is not monotone in K: y = 3 and 5 ulps make the cut remainder periodic in the trip count (2^29 mod 3
 * and mod 5), so some K far too small are right by chance (50, 200, 410, 500, 800 were). As for the
 * other widths the scan goes down from KMAX and stops at the first wrong K. */
struct extFloat80M { uint64_t signif; uint16_t signExp; };
int32_t cqrt_alloc_f80(long double);
int32_t __cq_q_cqsf_frem_f80_11_t(int32_t, int32_t, int32_t); void __cq_q_cqsf_frem_f80_11_t_unc(int32_t, int32_t, int32_t, int32_t);
struct extFloat80M cqsfi_frem_f80(struct extFloat80M, struct extFloat80M);
static long double ld(struct extFloat80M a) { long double x = 0; memcpy(&x, &a.signif, 8); memcpy((char *)&x + 8, &a.signExp, 2); return x; }
static int kt80_ok(int k) {
    struct extFloat80M xs[] = {{0xFFFFFFFFFFFFFFFFu, 0x7FFE}, {0xFFFFFFFFFFFFFFFEu, 0x7FFE}, {0xFFFFFFFFFFFFFFF8u, 0xFFFE}},
                       ys[] = {{1, 0}, {3, 0}, {5, 0x8000}};
    int ok = 1;
    for (int i = 0; i < 3; i++) for (int j = 0; j < 3; j++) {
        int32_t a = cqrt_alloc_f80(ld(xs[i])), b = cqrt_alloc_f80(ld(ys[j]));
        int32_t r = __cq_q_cqsf_frem_f80_11_t(a, b, k);
        struct extFloat80M w = cqsfi_frem_f80(xs[i], ys[j]);
        u128 want = (u128)w.signif | ((u128)w.signExp << 64);
        if ((toy_val(r) & (((u128)1 << 80) - 1)) != want) ok = 0;
        __cq_q_cqsf_frem_f80_11_t_unc(r, a, b, k);
        cqrt_free(b); cqrt_free(a);
    }
    return ok;
}
static int kt_f80(int kmax) {
    int kmin = -1;
    for (int k = kmax; k >= 1; k--) { if (!kt80_ok(k)) break; kmin = k; }
    printf("frem_f80: smallest K right on the worst cases = %d (shims pass %d)\n", kmin, kmax);
    return kmin;
}
int main(int argc, char **argv) {
    if (argc > 1) { for (int i = 1; i < argc; i++) { int k = atoi(argv[i]); printf("K %d: %s\n", k, kt80_ok(k) ? "right" : "wrong"); } return 0; }
    return kt_f80(1200) < 1;
}
#else
int main(void) {
    int a = kt_f16(), b = kt_f32(), c = kt_f64();
    return (a < 1 || b < 1 || c < 1) ? 1 : 0;
}
#endif
