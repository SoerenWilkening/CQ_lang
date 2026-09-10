#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0, 0.5); bool c = cq_theta((bool)0, 0.3); bool d = cq_theta((bool)0, 0.7); bool r = b ? c : d; return cq_measure(r) + cq_measure(b); }
