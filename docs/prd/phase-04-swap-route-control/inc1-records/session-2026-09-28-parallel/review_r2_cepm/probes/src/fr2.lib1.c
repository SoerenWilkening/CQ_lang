#include "CQ.h"
int ext_f(int a);
int F(int n) { int r = cq_theta(n, .3); int y = 0; if (r > 5) y = ext_f(7); return y; }
int G(int n) { return n * 5 + 1; }
