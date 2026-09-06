int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5);
  int y=5; if (q>5) y=ext_f(7);
  int m = y + 7;
  if ((m>>0)&1) cq_phi(0.7); if ((m>>1)&1) cq_phi(0.7);
  if ((m>>2)&1) cq_phi(0.7); if ((m>>3)&1) cq_phi(0.7);
  return cq_measure(m)+cq_measure(q); }
int main(void){ (void)slice(3); return 0; }
