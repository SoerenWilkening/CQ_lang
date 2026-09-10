#include "CQ.h"
int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; int m = cq_measure(b); return cq_measure(a) + m; }
