/* long double arithmetic on a quantum value: run_link_test.sh test/prog_f80.c with
 * CQSF_EXTRA_LIBS=-lqsoftfloat_f80 (main: prog_f80_main.c, a host object). */
#include <math.h>
static long double q(long double x0) { long double x = x0; cq_theta(&x, 0.0); return x; }
__attribute__((noinline)) long double g_a(long double x0) {
    long double x = q(x0);
    return cq_measure(sqrtl(x * 3.25L + 1.5L) / x - fmodl(x * 1e4000L, 7e-4000L));
}
__attribute__((noinline)) long long g_b(long double x0) {
    long double x = q(x0);
    return cq_measure((long long)(floorl(x * 1000.5L) + (x > 1.0L)) + (long long)(double)x);
}
