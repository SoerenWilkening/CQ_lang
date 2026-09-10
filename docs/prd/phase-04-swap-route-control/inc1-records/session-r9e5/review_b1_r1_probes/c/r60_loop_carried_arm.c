#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=1; for(int i=0;i<3;i++){ a = b ? a+1 : a; } return cq_measure(a)+cq_measure(b); }
