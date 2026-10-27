signed char add_i8(signed char x0, double th, signed char c) {
    signed char x = x0; cq_theta(&x, th); signed char y = x + c; return cq_measure(y); }
short add_i16(short x0, double th, short c) {
    short x = x0; cq_theta(&x, th); short y = x + c; return cq_measure(y); }
long long add_i64(long long x0, double th, long long c) {
    long long x = x0; cq_theta(&x, th); return cq_measure(x + c); }
_Bool and_i1(_Bool x0, _Bool y0, double tx, double ty) {
    _Bool x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty); _Bool z = x & y; return cq_measure(z); }
