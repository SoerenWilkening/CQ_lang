#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); b = cq_theta(b, 0.25); if (b) cq_phi(0.9); return cq_measure(b); }
