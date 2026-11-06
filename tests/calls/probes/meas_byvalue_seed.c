__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
int f(int a,int b){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  int m=cq_measure(a);
  int r=in(m)+in(b);
  return r+m;
}
