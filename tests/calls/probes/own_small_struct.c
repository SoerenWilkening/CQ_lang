typedef struct { int a; int b; } P;
int tab[8]={3,1,4,1,5,9,2,6};
__attribute__((noinline)) P q(int n){ P z={tab[n&7],n}; return z; }
int f(int a){ cq_theta(&a, 1.0); P p=q(3); return cq_measure(p.a)+p.b+cq_measure(a); }
