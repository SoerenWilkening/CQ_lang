__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
int f(int a,int b){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  int r=0, i=0;
  while(i<(b&3)){ r+=in(a+i); i++; }
  return cq_measure(r)+cq_measure(a);
}
