#include "CQ.h"
int main(void){ int q = cq_theta(3, 0.3); int r = cq_theta(7, 0.2); bool b = cq_theta((bool)0, 0.5); int s = b ? q : r; return cq_measure(s) + cq_measure(b); }
