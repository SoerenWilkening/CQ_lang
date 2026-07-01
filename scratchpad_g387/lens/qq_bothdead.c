#include <CQ.h>
#include <math.h>
double sink(double);
int main(void){ double x=cq_theta(0.0,0.5); double y=cq_theta(0.0,0.3); int q; double r=remquo(x,y,&q); (void)r; (void)q; return cq_measure((int)x)+cq_measure((int)y); }
