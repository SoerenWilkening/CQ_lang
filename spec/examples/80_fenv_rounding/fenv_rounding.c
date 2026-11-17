#include <fenv.h>
#pragma STDC FENV_ACCESS ON
#pragma clang fp exceptions(ignore)
double fenv_rounding(double x0, double th, double c, double k) {
    double x = x0;
    cq_theta(&x, th);
    fesetround(FE_UPWARD);                          /* classical mode */
    double y = x * c;                               /* rounded upward: the mode is a classical operand */
    fesetround(x > k ? FE_UPWARD : FE_DOWNWARD);    /* quantum mode: chosen by a quantum condition */
    double z = y + c;                               /* rounded under the quantum mode: the mode is a handle */
    int m = fegetround();                           /* reads the quantum mode */
    fesetround(FE_TONEAREST);                       /* classical again */
    double w = z * c;
    return cq_measure(w) + (double)cq_measure(m);
}
double quantum_mode_classical_op(double x0, double th, double k, double a, double b) {
    double x = x0;
    cq_theta(&x, th);
    fesetround(x > k ? FE_UPWARD : FE_DOWNWARD);    /* quantum mode */
    double s = a + b;                               /* classical operands, quantum mode: s is quantum */
    fesetround(FE_TONEAREST);
    return cq_measure(s);
}
