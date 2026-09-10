#include "CQ.h"
int main(void){ int q = cq_theta(0,0.3); double t = (double)q; bool b = cq_theta((bool)0,0.5); if (!b) cq_phi(t); return cq_measure(b)+cq_measure(q); }
