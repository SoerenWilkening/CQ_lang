#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); int q = cq_theta(0, 0.3); if (b) cq_phi(0.9); int s = q + b; return cq_measure(s); }
