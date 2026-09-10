#include "CQ.h"
int main(void){ int a = 5; bool b = cq_theta((bool)0, 0.5); int m = cq_measure(b); if (b) a -= 3; return cq_measure(a) + m; }
