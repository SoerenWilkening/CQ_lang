#include "CQ.h"
volatile double ta = 0.9, tb = 0.3;
int main(void){ double a = ta, c = tb; bool b = cq_theta((bool)0,0.5); if (b) cq_phi(a); else cq_phi(c); return cq_measure(b); }
