#include <CQ.h>
#include <math.h>
int main(void){ long double y=cq_theta((long double)0.0,0.3); int q; long double r=remquol((long double)7.0,y,&q); (void)r; return cq_measure(q); }
