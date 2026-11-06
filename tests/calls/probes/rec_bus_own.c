int tab[8]={3,1,4,1,5,9,2,6};
__attribute__((noinline)) int r(int n){ if(n<=0) return 0; return r(n-1)+tab[n&7]; }
int f(int a){ cq_theta(&a, 1.0); return cq_measure(r(a&3)); }
