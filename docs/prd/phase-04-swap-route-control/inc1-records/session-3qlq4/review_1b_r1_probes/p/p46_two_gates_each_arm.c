#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0,0.5); if (b) { cq_phi(0.9); cq_phi(0.4);} else { cq_phi(0.3); cq_phi(0.1);} return cq_measure(b); }
