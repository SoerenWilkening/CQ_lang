// cq-7prhl reduced (f16 division's case analysis): a quantum, b classical.
__attribute__((noinline)) static unsigned short h(unsigned short a, unsigned short b) {
  unsigned ae = (a >> 10) & 31, af = a & 1023, be = (b >> 10) & 31, bf = b & 1023;
  unsigned short s = (a ^ b) & 0x8000;
  if (ae == 31) {
    if (af) goto nan;
    if (be == 31) {
      if (bf) goto nan;
      return 0xfe00;
    }
    return s | 0x7c00;
  }
  if (be == 31) {
    if (bf) goto nan;
    return s;
  }
  if (be == 0) {
    if (bf == 0) {
      if ((ae | af) == 0) return 0xfe00;
      return s | 0x7c00;
    }
    bf <<= 3;
    be = 1;
  }
  int e = (int)ae - (int)be;
  unsigned q = ((af | 1024) << 5) / (bf | 1024);
  if (e > 28 && (e > 29 || q > 300)) return s | 0x7c00;
  return s | (unsigned short)((e << 10) + q);
nan:
  return a | 512;
}
unsigned short f(unsigned short qa, unsigned short c) { cq_theta(&qa, 0.3); return cq_measure(h(qa, c)); }
unsigned short g_inf(unsigned short qa) { cq_theta(&qa, 0.3); return cq_measure(h(qa, 0x7c00)); }
unsigned short g_nan(unsigned short qa) { cq_theta(&qa, 0.3); return cq_measure(h(qa, 0x7c05)); }
unsigned short g_zero(unsigned short qa) { cq_theta(&qa, 0.3); return cq_measure(h(qa, 0x8000)); }
unsigned short g_sub(unsigned short qa) { cq_theta(&qa, 0.3); return cq_measure(h(qa, 0x0013)); }
unsigned short g_norm(unsigned short qa) { cq_theta(&qa, 0.3); return cq_measure(h(qa, 0x3c00)); }
