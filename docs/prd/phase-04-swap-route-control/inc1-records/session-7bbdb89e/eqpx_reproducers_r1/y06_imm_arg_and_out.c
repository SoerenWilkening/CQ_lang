int ext_f(int a);
__attribute__((noinline))
int run(int u, int n){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);
  int w = (y & 7) ^ n;
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
int main(void){ (void)run(5,9); return 0; }
