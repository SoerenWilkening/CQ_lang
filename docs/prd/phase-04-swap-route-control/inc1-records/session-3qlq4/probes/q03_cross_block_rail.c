#include "CQ.h"
volatile int g = 1; int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (g) q = cq_theta(q, 0.1); if (b) cq_phi(0.9); return cq_measure(b) + cq_measure(q); }
