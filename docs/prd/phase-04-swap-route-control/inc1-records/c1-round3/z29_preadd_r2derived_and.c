int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);
  int w = y & 7;
  int a = cq_theta(u,0.7);
  a = a + w;
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(a)+cq_measure(r)+cq_measure(y); }
int main(void){ (void)slice(5); return 0; }
