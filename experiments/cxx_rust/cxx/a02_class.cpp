#include "cq.hpp"
struct Frac { int n, d; Frac(int n, int d) : n(n), d(d) {}
  Frac operator+(const Frac &o) const { return {n * o.d + o.n * d, d * o.d}; }
  Frac operator*(const Frac &o) const { return {n * o.n, d * o.d}; }
  bool operator<(const Frac &o) const { return n * o.d < o.n * d; } };
ENTRY int f(int x, int y) { Frac a(q(x), 3), b(y, 5); Frac c = a + b * a; return c < b ? c.n : c.d; }
