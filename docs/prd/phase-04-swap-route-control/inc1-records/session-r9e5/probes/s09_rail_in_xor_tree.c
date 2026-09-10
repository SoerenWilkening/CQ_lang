#include "CQ.h"
int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); bool c = cq_theta((bool)0, 0.3); if (b != c) a -= 3; return cq_measure(a) + cq_measure(b) + cq_measure(c); }
