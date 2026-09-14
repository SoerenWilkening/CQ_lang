#include "CQ.h"
int main(void) { int a = 5; bool b = 0; if (a >= 3) { b = cq_theta(b, 0.5); } return cq_measure(b) + cq_measure(a); }
