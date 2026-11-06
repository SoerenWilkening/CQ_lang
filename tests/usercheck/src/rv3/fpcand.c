int g;
__attribute__((noinline)) int l1(int x){ int i=0; while(i*i<(x&63)){ g^=i+1; i++; } return i; }
__attribute__((noinline)) int l2(int x){ return x+3; }
int f(int a,int b){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  int (*fp)(int)= (a&128)?l1:l2;
  int r=fp(b);
  return cq_measure(r)+64*cq_measure(g);
}
