__attribute__((noinline)) int in(int x){ if (x&1) return x; return cq_measure(x)+1; }
int f(int a){
  cq_theta(&a, 1.0);
  int r=in(a+1);
  return cq_measure(r)+cq_measure(a);
}
