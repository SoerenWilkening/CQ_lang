#include "CQ.h"
int main(void){ int q = cq_theta(0,0.3);
 { bool t = cq_theta((bool)0,0.2); if (t) cq_phi(0.7); q = cq_theta(q,0.1); }
 { bool t = cq_theta((bool)0,0.2); if (t) cq_phi(0.7); q = cq_theta(q,0.1); }
 { bool t = cq_theta((bool)0,0.2); if (t) cq_phi(0.7); q = cq_theta(q,0.1); }
 return cq_measure(q); }
