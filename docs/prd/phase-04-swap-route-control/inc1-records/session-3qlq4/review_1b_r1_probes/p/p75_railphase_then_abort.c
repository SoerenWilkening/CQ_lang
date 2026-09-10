#include "CQ.h"
#include <stdlib.h>
int main(void){ int q = cq_theta(5,0.5); bool c = cq_theta((bool)0,0.4); if (!c) cq_phi(0.7); if (q > 5) abort(); return cq_measure(q)+cq_measure(c); }
