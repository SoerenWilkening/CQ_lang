__attribute__((noinline)) int r(int n){ if(n<=0){ int x=n; cq_theta(&x,1.0); return x; } return r(n-1); }
int f(int a){ return cq_measure(r(a&3)); }
