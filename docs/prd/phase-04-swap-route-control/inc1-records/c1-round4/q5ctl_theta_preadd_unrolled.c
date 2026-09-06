int slice(void){ int p=7; p=cq_theta(p,0.25); p = p + 7;
  if ((p>>0)&1) cq_phi(0.7); if ((p>>1)&1) cq_phi(0.7);
  if ((p>>2)&1) cq_phi(0.7); if ((p>>3)&1) cq_phi(0.7);
  return cq_measure(p); }
int main(void){ (void)slice(); return 0; }
