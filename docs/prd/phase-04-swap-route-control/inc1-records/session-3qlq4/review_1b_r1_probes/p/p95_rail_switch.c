#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0,0.5); switch ((int)b) { case 0: cq_phi(0.3); break; case 1: cq_phi(0.9); break; } return cq_measure(b); }
