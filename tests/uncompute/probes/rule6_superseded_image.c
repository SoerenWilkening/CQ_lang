#include "CQ.h"
int g3(int x0, double th, int k) { int x = x0; cq_theta(&x, th); int c = x + k; if (x < 9) c ^= k; return cq_measure(c); }
int g3a(int x0, double th, int k) { int x = x0; cq_theta(&x, th); int c = x + k; c += 2 * x; return cq_measure(c); }
