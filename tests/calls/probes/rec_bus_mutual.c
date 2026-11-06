int tab[8]={3,1,4,1,5,9,2,6};
__attribute__((noinline)) int ev(int n);
__attribute__((noinline)) int od(int n){ if(n<=0) return 1; return ev(n-1)+tab[n&7]; }
__attribute__((noinline)) int ev(int n){ if(n<=0) return 0; return od(n-1)*2; }
int f(int a){ cq_theta(&a, 1.0); return cq_measure(ev(a&3))+cq_measure(a); }
