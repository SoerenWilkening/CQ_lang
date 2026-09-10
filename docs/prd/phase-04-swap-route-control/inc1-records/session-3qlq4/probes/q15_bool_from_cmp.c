#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.3); bool b = (q == 5); if (b) cq_phi(0.9); return cq_measure(q); }
