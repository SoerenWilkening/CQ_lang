int g;
static __attribute__((noinline)) int r(int n){ if(n<=0) return 0; g+=1; int v=r(n-1); return v*v+n; }
int f(int a){
  cq_theta(&a, 1.0);
  int v=0;
  if(a&64) v=r(a&15);
  if(a&128) v+=r(a&7);
  return cq_measure(v)+cq_measure(g);
}
