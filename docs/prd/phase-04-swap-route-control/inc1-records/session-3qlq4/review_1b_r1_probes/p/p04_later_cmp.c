#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.7); int q = cq_theta(0,0.3); if (b) q = q + 1; return cq_measure(q); }
