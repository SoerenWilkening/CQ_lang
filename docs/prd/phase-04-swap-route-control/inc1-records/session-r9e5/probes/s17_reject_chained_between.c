#include "CQ.h"
int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); bool c = cq_theta(b, 0.25); if (b) a -= 3; return cq_measure(a) + cq_measure(c); }
