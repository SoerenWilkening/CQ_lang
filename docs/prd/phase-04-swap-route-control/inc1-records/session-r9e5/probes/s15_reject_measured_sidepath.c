#include "CQ.h"
volatile int g = 1;
int main(void){ int a = 5; int m = 0; bool b = cq_theta((bool)0, 0.5); if (g) m = cq_measure(b); if (b) a -= 3; return cq_measure(a) + m; }
