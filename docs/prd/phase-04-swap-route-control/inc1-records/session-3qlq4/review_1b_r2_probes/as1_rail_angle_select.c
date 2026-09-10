#include "CQ.h"
int main(void){ bool b=cq_theta((bool)0,0.5); double a = b ? 0.9 : 0.3; cq_phi(a); return cq_measure(b); }
