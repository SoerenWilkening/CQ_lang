__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
int f(int a,int k){
  cq_theta(&a, 1.0);
  int y=a+1, r=0;
  if(k) r=in(y);
  int z=y*3;
  return r+cq_measure(z)+cq_measure(a);
}
