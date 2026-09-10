#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.7); b = cq_theta(b, 0.2); return cq_measure(b); }
