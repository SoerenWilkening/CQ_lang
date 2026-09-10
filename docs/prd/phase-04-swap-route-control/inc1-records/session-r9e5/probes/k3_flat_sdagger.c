#include "CQ.h"
int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; b = cq_theta(b, -0.5); return cq_measure(b) + cq_measure(a); }
