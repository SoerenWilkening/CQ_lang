__attribute__((noinline)) int r(int n){ if(n<=0) return 0; int v=r(n-1); return v*v+n; }
int f(int a){
  cq_theta(&a, 1.0);
  int (*volatile vp)(int)=r;
  int v=vp(a&15);
  return cq_measure(v);
}
