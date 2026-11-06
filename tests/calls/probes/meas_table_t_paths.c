__attribute__((noinline)) int sumin(int x,int n){ int s=0; for(int i=0;i<(n&3);i++) s+=cq_measure(x+i); return s+x; }
__attribute__((noinline)) int id(int x,int n){ return x+n; }
int f(int a,int k,int n){
  int (*p)(int,int) = k ? sumin : id;
  cq_theta(&a, 1.0);
  int r=p(a+1,n);
  return r+cq_measure(a);
}
__attribute__((noinline)) int some(int x,int n){ if(n&1) return cq_measure(x)+x; return x+2; }
int g(int a,int k,int n){
  int (*p)(int,int) = k ? some : id;
  cq_theta(&a, 1.0);
  int r=p(a+1,n);
  return r+cq_measure(a);
}
