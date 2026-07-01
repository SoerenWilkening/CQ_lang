#include <CQ.h>
#include <math.h>
int main(void){ double y=cq_theta(0.0,0.3); int q; double r=remquo(7.0,y,&q); return cq_measure((int)r)+cq_measure(q); }
