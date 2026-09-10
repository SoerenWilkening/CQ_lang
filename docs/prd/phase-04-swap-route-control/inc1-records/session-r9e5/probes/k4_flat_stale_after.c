#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.9); bool t = cq_theta(b, 0.1); if (b) cq_phi(0.3); return cq_measure(b) + cq_measure(t); }
