__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
__attribute__((noinline)) int g(int x,int y){ return in(x+1)+y; }
int f(int a,int b){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  int s=g(a,b)*3;
  return cq_measure(s)+cq_measure(b);
}
