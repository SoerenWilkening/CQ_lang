#include "CQ.h"
#include <stdlib.h>
int main(void){ bool b = cq_theta((bool)0,0.5); bool c = cq_theta((bool)0,0.4); if (b) abort(); if (!c) cq_phi(0.7); return cq_measure(b)+cq_measure(c); }
