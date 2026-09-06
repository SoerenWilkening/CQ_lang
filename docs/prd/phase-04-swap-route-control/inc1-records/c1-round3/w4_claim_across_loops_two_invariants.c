int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ r=cq_theta(r,0.1); }
  int y=5; if (q>5) y=ext_f(7);
  for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25); }
  return cq_measure(y)+cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
