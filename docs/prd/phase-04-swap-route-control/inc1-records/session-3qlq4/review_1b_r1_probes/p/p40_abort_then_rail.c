#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0,0.5); int q = cq_theta(0,0.3); if (q == 5) return cq_measure(b); if (!b) cq_phi(0.7); return cq_measure(b)+cq_measure(q); }
