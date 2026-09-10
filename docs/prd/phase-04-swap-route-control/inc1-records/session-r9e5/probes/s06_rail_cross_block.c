#include "CQ.h"
volatile int g = 1;
int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (g) cq_phi(0.7); if (b) a -= 3; return cq_measure(a) + cq_measure(b); }
