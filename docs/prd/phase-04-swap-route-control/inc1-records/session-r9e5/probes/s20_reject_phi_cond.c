#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); int a = 5; for (int i = 0; i < 3; ++i) { if (b) a -= 3; b = cq_theta(b, 0.1); } return cq_measure(a) + cq_measure(b); }
