#include "CQ.h"
volatile int v = 1;
int main(void){ bool b = cq_theta((bool)0,0.5); int r = 0; if (v) r = cq_measure(b); if (b) cq_phi(0.7); return r; }
