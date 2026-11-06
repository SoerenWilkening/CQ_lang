__attribute__((noinline)) int mm(int x,int k){ int y=x; if(k){ int t=cq_measure(y); return t+1; } return y; }
int f(int a,int b){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  int r=0;
  if (b&1) r=mm(a,1);
  return cq_measure(r)+7*cq_measure(a);
}
