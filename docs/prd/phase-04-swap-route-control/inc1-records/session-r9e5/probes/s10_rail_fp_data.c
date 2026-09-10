#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); double d = b ? 1.5 : 2.5; return (int) cq_measure(d) + cq_measure(b); }
