/* bd 8zj2 deliverable (4) — is the "cheaper fix" real?
 * (a) does CQ lower a TAINTED llvm.ctlz end-to-end?
 * (b) does LLVM's LoopIdiomRecognize convert a bit-scan loop to ctlz when the
 *     exit compare is `!= 0` rather than openlibm's `> 0`? */
double cq_theta_f64(double, double);
int cq_measure_si32(int);

/* (a) a tainted ctlz, via __builtin_clz on a quantum-derived word */
int probe_ctlz(void) {
  double q = cq_theta_f64(0.5, 0.5);
  long long b; __builtin_memcpy(&b, &q, 8);
  int hx = (int)(b >> 32) & 0x7fffffff;
  return cq_measure_si32(hx ? __builtin_clz((unsigned)hx) : 32);
}
