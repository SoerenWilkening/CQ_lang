#include "CQ.h"
int main(void){ int u = 0; int m = cq_measure(u); int q = cq_theta(0, 0.3); if (m) q = cq_theta(q, 0.5); return cq_measure(q); }
