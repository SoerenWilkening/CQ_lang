#include <stdarg.h>
int smin_q(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(x < c ? x : c);
}
unsigned bswap_q(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    return cq_measure(__builtin_bswap32(x));
}
unsigned usub_sat_q(unsigned x0, double th, unsigned c) {
    unsigned x = x0;
    cq_theta(&x, th);
    return cq_measure(x > c ? x - c : 0);
}
__attribute__((noinline)) static int sum_twice(int n, ...) {
    va_list ap, bp;
    va_start(ap, n);
    va_copy(bp, ap);
    int s = 0, t = 0;
    for (int i = 0; i < n; i++) s += va_arg(ap, int);
    for (int i = 0; i < n; i++) t += va_arg(bp, int);
    va_end(bp);
    va_end(ap);
    return s + t;
}
int va_copy_q(int x0, double th, int a) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(sum_twice(2, x, a));
}
__attribute__((noinline)) static void put(int *v, int val) { v[0] = val; }
int vla_loop_q(int x0, double th, int n, int m) {
    int x = x0;
    cq_theta(&x, th);
    int acc = 0;
    for (int i = 0; i < m; i++) {
        int v[n];
        put(v, x + i);
        acc += v[0];
    }
    return cq_measure(acc);
}
