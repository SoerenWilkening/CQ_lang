int g;
__attribute__((noinline)) int l(int x){ int i=0; while(i*i<(x&63)){ g^=i+1; i++; } return i; }
int f(int a,int b){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  int (*volatile vp)(int)=l;
  int r=vp(a);
  if(b&2) r+=vp(a>>1);
  return cq_measure(r)+64*cq_measure(g);
}
