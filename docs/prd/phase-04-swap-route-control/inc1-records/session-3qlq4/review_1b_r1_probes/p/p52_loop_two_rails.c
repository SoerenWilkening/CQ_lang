#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0,0.5); bool c = cq_theta((bool)0,0.4); int q = cq_theta(0,0.3); for (int i=0;i<3;++i){ if (b) cq_phi(0.7); if (c) cq_phi(0.2); q = cq_theta(q,0.2);} return cq_measure(b)+cq_measure(c)+cq_measure(q); }
