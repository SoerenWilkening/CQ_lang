typedef struct { int a; int b; } P;
int tab[8]={3,1,4,1,5,9,2,6};
__attribute__((noinline)) P r(int n){ if(n<=0){ P z={0,n}; return z; } P s=r(n-1); s.a+=tab[n&7]; return s; }
int f(int a){ cq_theta(&a, 1.0); P p=r(a&3); return cq_measure(p.a)+p.b; }
