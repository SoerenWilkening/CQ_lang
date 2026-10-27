double fmuladd_qcc(double x0, double th, double a, double b) {
    double x = x0; cq_theta(&x, th); return cq_measure(x * a + b); }
double fmuladd_qqq(double x0, double y0, double z0, double tx, double ty, double tz) {
    double x = x0, y = y0, z = z0; cq_theta(&x, tx); cq_theta(&y, ty); cq_theta(&z, tz);
    return cq_measure(x * y + z); }
