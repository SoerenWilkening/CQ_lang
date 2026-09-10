#include "CQ.h"
/* same as n04 but the measurement is of q, the cast's SOURCE — a different physical register; must ACCEPT */
int main(void){ int q = cq_theta(3, 0.2); bool t = (bool)(q & 1); bool b = cq_theta(t, 0.5); int m = cq_measure(q); int a = b ? 2 : 5; return m + cq_measure(a); }
