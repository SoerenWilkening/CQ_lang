#include "CQ.h"
volatile int v = 1;
int main(void){ bool b = cq_theta((bool)0,0.5); if (b && v) cq_phi(0.7); return cq_measure(b); }
