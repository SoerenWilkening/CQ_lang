#include <stdlib.h>
__attribute__((noinline)) void g(int x){ if(x==4) exit(4); }
__attribute__((noinline)) void f(int x){ g(x); }
int e(void){ char c=0; cq_theta(&c,.5); if(c&1) f(c); return cq_measure(c); }
