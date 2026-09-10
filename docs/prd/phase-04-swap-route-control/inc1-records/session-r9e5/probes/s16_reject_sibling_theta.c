#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.3); int a = 5; bool t = (bool)(q & 1); bool b = cq_theta(t, 0.5); bool c = cq_theta(t, 0.9); if (b) a -= 3; return cq_measure(a) + cq_measure(c); }
