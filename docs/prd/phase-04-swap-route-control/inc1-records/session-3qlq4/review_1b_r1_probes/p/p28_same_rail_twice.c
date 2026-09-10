#include "CQ.h"
volatile int vv = 1;
int main(void){ bool b = cq_theta((bool)0,0.5); bool c = (bool)vv; if ((b && c) || (b && !c)) cq_phi(0.7); return cq_measure(b); }
