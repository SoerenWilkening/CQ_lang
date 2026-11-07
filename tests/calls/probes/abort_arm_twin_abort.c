#include <stdlib.h>
__attribute__((noinline)) int f(int x){ if(x==3) abort(); return x+2; }
int e(void){ char c=0; cq_theta(&c,.5); int r=f(c); int z=r*r; return cq_measure(z); }
