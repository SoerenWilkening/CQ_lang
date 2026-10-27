double fadd_qc(double x0, double th, double c) { double x = x0; cq_theta(&x, th); return cq_measure(x + c); }
double fsub_qq(double x0, double y0, double tx, double ty) {
    double x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(x - y); }
double fmul_qq(double x0, double y0, double tx, double ty) {
    double x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(x * y); }
double fdiv_cq(double x0, double th, double c) { double x = x0; cq_theta(&x, th); return cq_measure(c / x); }
double fneg_q(double x0, double th)            { double x = x0; cq_theta(&x, th); return cq_measure(-x); }
