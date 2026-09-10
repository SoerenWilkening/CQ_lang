#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); bool c = cq_theta(b, 0.2); if (b) cq_phi(0.7); return cq_measure(c); }
