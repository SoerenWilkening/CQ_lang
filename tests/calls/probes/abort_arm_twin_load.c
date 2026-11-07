#include <stdlib.h>
int g[4];
__attribute__((noinline)) int f(int x){ int v=g[x&3]; if(v==3) abort(); return v+x; }
int e(void){ char c=0; cq_theta(&c,.5); int r=f(c); int z=r*r; g[1]=z; return cq_measure(z)+g[2]; }
