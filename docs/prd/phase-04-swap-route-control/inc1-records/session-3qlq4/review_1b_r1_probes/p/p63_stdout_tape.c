#include "CQ.h"
#include <stdio.h>
int main(void){ bool b = cq_theta((bool)0,0.5); if (b) cq_phi(0.7); int m = cq_measure(b); printf("%d\n", m); return 0; }
