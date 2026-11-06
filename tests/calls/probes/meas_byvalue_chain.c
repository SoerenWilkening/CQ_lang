__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
__attribute__((noinline)) int g(int x){ return in(x)*2; }
int f(int a){
  cq_theta(&a, 1.0);
  int r=g(a+1);
  return r+cq_measure(a);
}
