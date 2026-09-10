#include "CQ.h"
/* the condition rail b is a chained theta on the TEMPLATE parent t; measuring t before the select collapses b's register */
int main(void){ int q = cq_theta(3, 0.2); bool t = (bool)(q & 1); bool b = cq_theta(t, 0.5); int m = cq_measure(t); int a = b ? 2 : 5; return m + cq_measure(a); }
