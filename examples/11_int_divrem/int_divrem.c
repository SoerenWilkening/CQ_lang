int sdiv_qc(int x0, double th, int c)           { int x = x0; cq_theta(&x, th); return cq_measure(x / c); }
unsigned udiv_qc(unsigned x0, double th, unsigned c) { unsigned x = x0; cq_theta(&x, th); return cq_measure(x / c); }
int srem_qc(int x0, double th, int c)           { int x = x0; cq_theta(&x, th); return cq_measure(x % c); }
unsigned urem_qq(unsigned x0, unsigned y0, double tx, double ty) {
    unsigned x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(x % y); }
