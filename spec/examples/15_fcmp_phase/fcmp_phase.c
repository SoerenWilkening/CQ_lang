double fcmp_olt(double x0, double th, double k, double phi) {
    double x = x0; cq_theta(&x, th);
    if (x < k) cq_phi(phi);
    return cq_measure(x); }
double fcmp_unordered(double x0, double th, double k, double phi) {
    double x = x0; cq_theta(&x, th);
    if (!(x >= k)) cq_phi(phi);
    return cq_measure(x); }
double fcmp_qq(double x0, double y0, double tx, double ty, double phi) {
    double x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty);
    if (x == y) cq_phi(phi);
    return cq_measure(x); }
