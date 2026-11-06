static int ev(int n);
static __attribute__((noinline)) int od(int n){ if(n<=0) return 0; return ev(n-1)+1; }
static __attribute__((noinline)) int ev(int n){ if(n<=0) return 1; return od(n-1)*2; }
int f(int a){
  cq_theta(&a, 1.0);
  int v=0;
  if(a&64) v=ev(a&15);
  return cq_measure(v);
}
