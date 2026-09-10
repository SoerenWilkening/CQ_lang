#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0,0.5); bool arr[2]; arr[0]=b; arr[1]=0; if (arr[0]) cq_phi(0.7); return cq_measure(b); }
