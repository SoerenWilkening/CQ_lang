__attribute__((noinline)) int r(int n){ int i=0; for(;;){ if(i>=n){ int x=i; cq_theta(&x,1.0); return x; } i++; if(i==3){ int y=i+10; cq_theta(&y,0.5); return y; } } }
int f(int a){ return cq_measure(r(a&7)); }
