#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.9); b = cq_theta(b, 0.25); return cq_measure(b); }
