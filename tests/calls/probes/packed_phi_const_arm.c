typedef struct{int a,b;} P;
__attribute__((noinline)) P f(int x){ P p={x+1,x*2}; return p; }
int e(int k){ char c=0; cq_theta(&c,.5); P p={1,2}; if(k&1) p=f(c); return cq_measure(p.a)+cq_measure(p.b); }
