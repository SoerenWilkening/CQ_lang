#include <stdlib.h>
__attribute__((noinline)) void f(int k){ if(k&2) exit(4); }
int e(int k){ char c=0; cq_theta(&c,.5); if(c&1) f(k); return cq_measure(c); }
