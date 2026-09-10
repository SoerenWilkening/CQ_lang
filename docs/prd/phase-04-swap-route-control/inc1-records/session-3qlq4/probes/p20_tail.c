#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); double t = 0.3; if (b) t = 0.9; cq_phi(t); return cq_measure(b); }
