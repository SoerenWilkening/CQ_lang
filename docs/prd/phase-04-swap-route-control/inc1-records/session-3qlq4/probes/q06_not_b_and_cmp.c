#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (!b && q == 5) cq_phi(0.9); return cq_measure(b) + cq_measure(q); }
