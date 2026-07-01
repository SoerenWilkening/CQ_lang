#include <CQ.h>
#include <math.h>
int main(void){ double x=cq_theta(0.0,0.5); int q; double r=remquo(x,3.0,&q); volatile int sink=q; (void)sink; return cq_measure((int)r); }
