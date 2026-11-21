// cq-7prhl reduced (2): fma's NaN propagation, x and y classical, z quantum. -O1 tests x's NaN again after the
// quantum test of z: an edge no path takes (x is not NaN there).
#define ISNAN(v) (((v) & 0x7c00) == 0x7c00 && ((v) & 0x3ff))
__attribute__((noinline)) static unsigned short h(unsigned short x, unsigned short y, unsigned short z) {
  if (ISNAN(x)) goto nan;
  if (ISNAN(y) || ISNAN(z)) goto nan;
  return (unsigned short)((unsigned)(x * y) / (unsigned)(z | 1));
nan:
  return (ISNAN(x) ? x : ISNAN(y) ? y : z) | 0x200;
}
unsigned short f(unsigned short x, unsigned short y, unsigned short qz) {
  cq_theta(&qz, 0.3);
  return cq_measure(h(x, y, qz));
}
unsigned short g_ynan(unsigned short x, unsigned short qz) { return f(x, 0x7c01, qz); }
unsigned short g_xnan(unsigned short y, unsigned short qz) { return f(0x7c02, y, qz); }
unsigned short g_none(unsigned short qz) { return f(0x3c00, 0x4000, qz); }
