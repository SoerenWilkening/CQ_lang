#include "CQ.h"
int main(void){ int a = 5; int c = 7; bool b = cq_theta((bool)0, 0.5); if (b) a -= 3; if (b) c += 1; return cq_measure(a) + cq_measure(c) + cq_measure(b); }
