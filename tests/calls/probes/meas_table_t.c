__attribute__((noinline)) int in(int x){ return cq_measure(x)+1; }
__attribute__((noinline)) int in2(int x){ return cq_measure(x)+2; }
int f(int a,int k){
  int (*p)(int) = k ? in : in2;
  cq_theta(&a, 1.0);
  int r=p(a+1);
  return r+cq_measure(a);
}
__attribute__((noinline)) int twice(int x){ int m=cq_measure(x); return m+x+cq_measure(x); }
int g(int a,int k){
  int (*p)(int) = k ? twice : in;
  int r=p(a+1);
  return r+cq_measure(a);
}
__attribute__((noinline)) int meas(int x){ return cq_measure(x); }
__attribute__((noinline)) int outer(int x){ return meas(x)+x; }
int h(int a,int k){
  int (*p)(int) = k ? outer : in;
  cq_theta(&a, 1.0);
  int r=p(a+1);
  return r+cq_measure(a);
}
__attribute__((noinline)) int inner(int x){ return cq_measure(x+1)+x; }
int n(int a,int k){
  int (*p)(int) = k ? inner : in;
  cq_theta(&a, 1.0);
  int r=p(a+1);
  return r+cq_measure(a);
}
