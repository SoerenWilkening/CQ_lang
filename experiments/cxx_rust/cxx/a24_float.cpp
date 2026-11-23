#include "cq.hpp"
#include <cmath>
template <class F> static double newton(F f, double x0) { double x = x0; for (int i = 0; i < 3; i++) x = x - f(x) / (2 * x); return x; }
ENTRY double f(int x, int y) { double a = q((double)x); return newton([a](double z) { return z * z - a; }, 1.0 + y) + std::fabs(a); }
