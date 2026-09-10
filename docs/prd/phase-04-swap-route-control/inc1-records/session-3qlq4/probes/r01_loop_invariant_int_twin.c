#include "CQ.h"
int main(void){ int b = cq_theta(0, 0.5); int q = cq_theta(0, 0.3); for (int i = 0; i < 3; ++i) { if (b == 1) cq_phi(0.1 * i); q = cq_theta(q, 0.2); } return cq_measure(b) + cq_measure(q); }
