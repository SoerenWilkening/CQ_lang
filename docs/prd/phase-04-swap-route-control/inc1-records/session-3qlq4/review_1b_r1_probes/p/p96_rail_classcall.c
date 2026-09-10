#include "CQ.h"
__attribute__((noinline,const)) static int pure3(int x){ return x*3; }
int main(void){ bool b = cq_theta((bool)0,0.5); int q = cq_theta(0,0.3); if (b) q = pure3(7); return cq_measure(q)+cq_measure(b); }
