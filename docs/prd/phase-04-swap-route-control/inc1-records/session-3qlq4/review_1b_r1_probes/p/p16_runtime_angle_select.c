#include "CQ.h"
int slice(double a, double c){ bool b = cq_theta((bool)0,0.5); if (b) cq_phi(a); else cq_phi(c); return cq_measure(b); }
int main(void){ return slice(0.9,0.3); }
