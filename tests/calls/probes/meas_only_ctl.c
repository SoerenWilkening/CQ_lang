__attribute__((noinline)) int mm(int x){ return cq_measure(x)+1; }
int f(int a,int b){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  int r=0;
  if (b&1) r=mm(a);
  return cq_measure(r)+7*cq_measure(a);
}
