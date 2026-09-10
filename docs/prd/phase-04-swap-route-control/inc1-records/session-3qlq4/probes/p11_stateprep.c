#include "CQ.h"
int main(void){ int r = 1; bool b = cq_theta((bool)0, 0.5); if (b) r = cq_theta(1, 0.9); return cq_measure(r) + cq_measure(b); }
