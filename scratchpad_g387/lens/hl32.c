#include <CQ.h>
#include <math.h>
int main(void){ float x=cq_theta(0.0f,0.5); int q; float r=remquof(x,3.0f,&q); return cq_measure((int)r)+cq_measure(q); }
