#include "cq.hpp"
#include <complex>
ENTRY double f(int x, int y) { std::complex<double> a(q((double)x), 1.0), b(2.0, y); auto c = a * b + a; return c.real() - c.imag(); }
