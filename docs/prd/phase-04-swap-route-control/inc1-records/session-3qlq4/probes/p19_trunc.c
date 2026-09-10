#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.3); if (q & 1) cq_phi(0.9); return cq_measure(q); }
