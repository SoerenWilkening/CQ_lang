#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0,0.5); double t; if (!b) t = 0.9; else t = 0.3; cq_phi(t); return cq_measure(b); }
