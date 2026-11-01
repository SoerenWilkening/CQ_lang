__attribute__((noinline)) static void f(int v, int *p, int *q){ *p = *q + v; }
int te3(int x0, double th){ int x=x0; cq_theta(&x,th); int s = x*5; f(x,&s,&s); return cq_measure(s + x); }
