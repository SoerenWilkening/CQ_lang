int sub_qc(int x0, double th, int c)  { int x = x0; cq_theta(&x, th); return cq_measure(x - c); }
int mul_qq(int x0, int y0, double tx, double ty) {
    int x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(x * y); }
int shl_qc(int x0, double th, int c)  { int x = x0; cq_theta(&x, th); return cq_measure(x << c); }
unsigned lshr_qq(unsigned x0, unsigned y0, double tx, double ty) {
    unsigned x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(x >> y); }
int ashr_qc(int x0, double th, int c) { int x = x0; cq_theta(&x, th); return cq_measure(x >> c); }
int and_qc(int x0, double th, int c)  { int x = x0; cq_theta(&x, th); return cq_measure(x & c); }
int or_qq(int x0, int y0, double tx, double ty) {
    int x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(x | y); }
int xor_qq(int x0, int y0, double tx, double ty) {
    int x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); return cq_measure(x ^ y); }
