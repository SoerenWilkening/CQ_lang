typedef struct{int a,b;} P;
__attribute__((noinline)) P f(int x){ P p={x+1,x*2}; return p; }
__attribute__((noinline)) P g(int x){ P p={x,~x}; return p; }
int e(int k){ char c=0; cq_theta(&c,.5); P p; if(k&1) p=f(c); else p=g(c); return cq_measure(p.a)+cq_measure(p.b); }
