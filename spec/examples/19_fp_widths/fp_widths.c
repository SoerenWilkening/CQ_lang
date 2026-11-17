float fadd_f32(float x0, double th, float c)  { float x = x0; cq_theta(&x, th); return cq_measure(x + c); }
long double fadd_f80(long double x0, double th, long double c) {
    long double x = x0; cq_theta(&x, th); return cq_measure(x + c); }
long double fmul_f80_qq(long double x0, long double y0, double tx, double ty) {
    long double x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(x * y); }
