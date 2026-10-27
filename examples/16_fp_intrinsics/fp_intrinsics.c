#include <math.h>
double fabs_q(double x0, double th)              { double x = x0; cq_theta(&x, th); return cq_measure(fabs(x)); }
double copysign_qc(double x0, double th, double s) { double x = x0; cq_theta(&x, th); return cq_measure(copysign(x, s)); }
double sqrt_q(double x0, double th)              { double x = x0; cq_theta(&x, th); return cq_measure(sqrt(x)); }
double floor_q(double x0, double th)             { double x = x0; cq_theta(&x, th); return cq_measure(floor(x)); }
double trunc_q(double x0, double th)             { double x = x0; cq_theta(&x, th); return cq_measure(trunc(x)); }
double rint_q(double x0, double th)              { double x = x0; cq_theta(&x, th); return cq_measure(rint(x)); }
double fmax_qc(double x0, double th, double c)   { double x = x0; cq_theta(&x, th); return cq_measure(fmax(x, c)); }
