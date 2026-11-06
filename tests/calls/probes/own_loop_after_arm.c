int t[4];
__attribute__((noinline)) int r(int n, int s){ int k=0; if(n<=0){ int x=n; cq_theta(&x,1.0); return x; } for(int i=0;i<s;i++){ if(i&1) k+=3; else k+=5; } int y=k; cq_theta(&y,0.5); return y; }
int f(int a){ return cq_measure(r(a&1, a&3)); }
