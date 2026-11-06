__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
int (*volatile fp)(int)=in;
int f(int a){
  cq_theta(&a, 1.0);
  int r=fp(a+1);
  return cq_measure(r)+cq_measure(a);
}
