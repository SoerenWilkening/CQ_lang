// Rules 2, 18: the result of a clone that loads from the bus, read by a measurement only. _t and _t_ctl measure a copy, and so does
// a caller measuring it on some classical paths: the result is then uncomputed, and its twin is emitted.
__attribute__((noinline)) long rd(const char *p) { return p[0] + p[1]; }
int f(char a) {
  char b[2] = {a, 0};
  cq_theta(&b[0], 0.3);
  return (int)cq_measure(rd(b));
}
int g(char a, int n) {
  char b[2] = {a, 0};
  cq_theta(&b[0], 0.3);
  long r = rd(b);
  if (n == 1)
    return (int)cq_measure(r) + 1;
  if (n == 2)
    return (int)cq_measure(r) * 3;
  return 0;
}
