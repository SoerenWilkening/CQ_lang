#include "cq.hpp"
struct Shape { virtual int area(int k) const = 0; virtual ~Shape() {} };
struct Sq : Shape { int s; Sq(int s) : s(s) {} int area(int k) const override { return s * s + k; } };
struct Rect : Shape { int a, b; Rect(int a, int b) : a(a), b(b) {} int area(int k) const override { return a * b - k; } };
__attribute__((noinline)) int total(const Shape *const *s, int n, int k) { int t = 0; for (int i = 0; i < n; i++) t += s[i]->area(k); return t; }
ENTRY int f(int x, int y) { Sq s(q(x)); Rect r(x, y); const Shape *v[2] = {&s, &r}; return total(v, 2, q(y)); }
