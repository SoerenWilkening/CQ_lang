#include "CQ.h"
volatile int idx = 1;
int main(void){ bool arr[4] = {0,0,0,0}; int i = idx; arr[i] = cq_theta((bool)0,0.5); bool b = arr[i]; if (b) cq_phi(0.7); return cq_measure(b); }
