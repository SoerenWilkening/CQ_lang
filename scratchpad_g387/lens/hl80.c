#include <CQ.h>
#include <math.h>
int main(void){ long double x=cq_theta((long double)0.0,0.5); int q; long double r=remquol(x,(long double)3.0,&q); (void)r; return cq_measure(q); }
