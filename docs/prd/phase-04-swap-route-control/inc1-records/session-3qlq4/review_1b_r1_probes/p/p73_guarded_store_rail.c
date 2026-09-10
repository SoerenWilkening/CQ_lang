#include "CQ.h"
volatile int idx=0;
int main(void){ int a[4]={0,0,0,0}; bool b = cq_theta((bool)0,0.5); int i=idx; if (b) a[i]=3; return cq_measure(b)+a[1]; }
