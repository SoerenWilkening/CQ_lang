__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
int f(int a){
  cq_theta(&a, 1.0);
  int r=in(a+1);
  return r+cq_measure(a);
}
