/* tests/spine probe (cq-366o; CR rules 8, 9): a classical phi whose block a linearized output edge reaches under
 * classical facts that admit none of its original edges (under x == 0 every quantum arm returned: musl powl's
 * x <= 0 cases inside exp10l): the phi is a don't-care there.
 * Regenerate: clang -O1 -frounding-math -include CQ.h phi_dontcare.c -o phi_dontcare.ll */
__attribute__((noinline)) static double g(double x, double y) {
  int yi = __builtin_floor(y) == y;
  int yodd = yi && __builtin_floor(0.5 * y) != 0.5 * y;
  int neg = 0;
  if (x <= 0.0) {
    if (x == 0.0) {
      if (y < 0.0) { if (yodd) return -1.0 / 0.0; return 1.0 / 0.0; }
      if (yodd) return -0.0;
      return 0.0;
    }
    if (!yi) return (x - x) / (x - x);
    x = -x;
    neg = yodd;
  }
  double r = x * y + 1.0;
  if (yi && __builtin_floor(r) == r) r = r * 0.5;
  return neg ? -r : r;
}
double pd(double a, double x) { double y = a; cq_theta(&y, 0.5); return cq_measure(g(x, y)); }
