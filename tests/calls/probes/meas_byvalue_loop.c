__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
int f(int a,int n){
  cq_theta(&a, 1.0);
  int r=0;
  for(int i=0;i<n;i++) r+=in(a+i);
  return r+cq_measure(a);
}
