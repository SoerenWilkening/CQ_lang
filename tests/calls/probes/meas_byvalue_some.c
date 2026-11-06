__attribute__((noinline)) int in(int x,int k){ if(k) return cq_measure(x)+1; return x; }
int f(int a,int k){
  cq_theta(&a, 1.0);
  int r=in(a+1,k);
  return cq_measure(r)+cq_measure(a);
}
