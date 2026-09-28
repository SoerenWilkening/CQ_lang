#include "CQ.h"
int F(int n) { int r = cq_theta(n, .3); return n + cq_measure(r); }
