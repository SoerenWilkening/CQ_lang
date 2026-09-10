#include "CQ.h"
int main(void){ bool b0 = cq_theta((bool)0,0.1); bool b = cq_theta(b0,0.2); if (b) cq_phi(0.7); return cq_measure(b0); }
