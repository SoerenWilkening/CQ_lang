/* A program with double (and float) arithmetic on a quantum value, for the link test (run_link_test.sh).
 * cq_theta(&x, 0) makes x quantum and leaves its basis value; every float operation on it becomes a
 * float template, which libqsoftfloat.a provides. Each function returns one measured (classical) result;
 * main (prog_double_main.c, an ordinary host object, not lowered) prints them, so the toy backend needs
 * neither the bus nor the tape. Built natively with cq_theta a no-op and cq_measure the identity, the
 * same two files print the expected line. */
#include <math.h>
#include <stdio.h>

static double q(double x0) { double x = x0; cq_theta(&x, 0.0); return x; }

__attribute__((noinline)) double f_y(double x0) {
    double x = q(x0);
    return cq_measure((x * 3.25 + 1.5) / x);                      /* fmul, fadd, fdiv with literals */
}
__attribute__((noinline)) double f_z(double x0) {
    double x = q(x0), y = (x * 3.25 + 1.5) / x;
    return cq_measure(sqrt(y) - fmod(y, 0.75));                  /* sqrt, frem, fsub */
}
__attribute__((noinline)) int f_k(double x0) {
    double x = q(x0), y = (x * 3.25 + 1.5) / x;
    return cq_measure((int)((sqrt(y) - fmod(y, 0.75)) * 1000.0)); /* fptosi */
}
__attribute__((noinline)) double f_w(int k0) {
    int k = k0; cq_theta(&k, 0.0);
    return cq_measure((double)k + floor((double)k / 7.0));       /* sitofp, floor */
}
__attribute__((noinline)) float f_f(double x0) {
    double x = q(x0);
    return cq_measure((float)x * 0.5f - 1.0f / 3.0f);            /* fptrunc, f32 fmul and fsub */
}
__attribute__((noinline)) double f_v(double x0) {
    double x = q(x0);
    return cq_measure((double)(float)x / (x - x0));              /* fpext, division by zero: +Inf */
}
__attribute__((noinline)) int f_c(double x0) {
    double x = q(x0);
    return cq_measure((x > 3.0) + 2 * isinf(x / 0.0) + 4 * (x != x)); /* fcmp, is_fpclass */
}
__attribute__((noinline)) double f_m(double x0) {
    double x = q(x0);
    return cq_measure(fmax(x * x, 4.5) + fma(x, x, -1.0));       /* fmax, fma */
}
__attribute__((noinline)) double f_r(double x0) {
    double x = q(x0);
    return cq_measure(fmod(x * 1e300, 3e-300));                  /* frem's longest loop */
}
