#include "CQ.h"
int slice(double t){ bool b = cq_theta((bool)0,0.5); if (!b) cq_phi(t); return cq_measure(b); }
int main(void){ return slice(0.7); }
