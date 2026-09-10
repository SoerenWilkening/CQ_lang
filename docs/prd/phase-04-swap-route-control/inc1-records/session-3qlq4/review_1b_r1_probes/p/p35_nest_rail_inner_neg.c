#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0,0.5); bool c = cq_theta((bool)0,0.3); if (b) { cq_phi(0.2); if (!c) cq_phi(0.9);} return cq_measure(b)+cq_measure(c); }
