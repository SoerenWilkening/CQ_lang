int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);
  int w = y * 3;
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r = r + w; }
  return cq_measure(r)+cq_measure(y); }
int main(void){ (void)slice(5); return 0; }
