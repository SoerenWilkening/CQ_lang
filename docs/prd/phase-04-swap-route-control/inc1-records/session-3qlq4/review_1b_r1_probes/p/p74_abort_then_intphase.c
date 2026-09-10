#include "CQ.h"
#include <stdlib.h>
int main(void){ int q = cq_theta(5,0.5); int r = cq_theta(3,0.4); if (q > 5) abort(); if (r != 3) cq_phi(0.7); return cq_measure(q)+cq_measure(r); }
