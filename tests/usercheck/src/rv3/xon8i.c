static __attribute__((noinline)) int r(int n){ if(n<=0) return 0; int v=r(n-1); return v*2+n; }
int f(int a){
  cq_theta(&a, 1.0);
  int v=r(a&7);
  return cq_measure(v);
}

CQ_K(r, 2)
