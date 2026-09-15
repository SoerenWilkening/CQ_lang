#include "CQ.h"
int main(void){ int u = 0; int q = cq_theta(0, 0.3); int a = 1; if (q == 3) { a = cq_measure(u) + 2; } return cq_measure(q) + a; }
