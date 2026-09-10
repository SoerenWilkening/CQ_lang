#include "CQ.h"
volatile double th = 0.7;
int main(void){ double t = th; bool b = cq_theta((bool)0,0.5); if (!b) cq_phi(t); return cq_measure(b); }
