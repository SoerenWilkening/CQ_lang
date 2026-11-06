__attribute__((noinline)) int ev(int n);
__attribute__((noinline)) int od(int n){ if(n<=0){ int x=n; cq_theta(&x,1.0); return x; } return ev(n-1)*3; }
__attribute__((noinline)) int ev(int n){ if(n<=0) return 1; return od(n-1)+5; }
int f(int a){ return cq_measure(ev(a&3)); }
