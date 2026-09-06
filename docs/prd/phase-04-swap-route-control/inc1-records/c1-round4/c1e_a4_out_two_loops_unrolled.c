int slice(void){ int q=3,p=7; q=cq_theta(q,0.5); p=cq_theta(p,0.25);
  if (q>3){ p=p*5; p=p^9; }
  p = p + 7;
  if ((p>>0)&1) cq_phi(0.7);
  if ((p>>1)&1) cq_phi(0.7);
  if ((p>>2)&1) cq_phi(0.7);
  if ((p>>3)&1) cq_phi(0.7);
  p = p + 5;
  if ((p>>0)&1) cq_phi(0.3);
  if ((p>>1)&1) cq_phi(0.3);
  if ((p>>2)&1) cq_phi(0.3);
  if ((p>>3)&1) cq_phi(0.3);
  return cq_measure(p); }
int main(void){ (void)slice(); return 0; }
