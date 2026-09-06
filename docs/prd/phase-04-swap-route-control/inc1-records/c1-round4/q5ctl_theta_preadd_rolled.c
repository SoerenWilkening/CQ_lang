int slice(void){ int p=7; p=cq_theta(p,0.25); p = p + 7;
  for (int i=0;i<4;i++) if ((p>>i)&1) cq_phi(0.7);
  return cq_measure(p); }
int main(void){ (void)slice(); return 0; }
