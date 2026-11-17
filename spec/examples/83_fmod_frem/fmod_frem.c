#include <math.h>
double fmod_qc(double x0, double th, double c)  { double x = x0; cq_theta(&x, th); return cq_measure(fmod(x, c)); }
double fmod_cq(double x0, double th, double c)  { double x = x0; cq_theta(&x, th); return cq_measure(fmod(c, x)); }
float fmodf_qq(float x0, float y0, double tx, double ty) {
    float x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(fmodf(x, y)); }
long double fmodl_qc(long double x0, double th, long double c) {
    long double x = x0; cq_theta(&x, th); return cq_measure(fmodl(x, c)); }
