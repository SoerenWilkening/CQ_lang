#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); if (b) cq_phi(0.7); int x = (int)b; x = x * 3; return cq_measure(x); }
