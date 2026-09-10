#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.3); int a = 5; if (q & 1) a -= 3; return cq_measure(a) + cq_measure(q); }
