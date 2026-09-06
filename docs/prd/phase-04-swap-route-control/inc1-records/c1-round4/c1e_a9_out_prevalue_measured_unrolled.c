int slice(void){ int q=3,p=7; q=cq_theta(q,0.5); p=cq_theta(p,0.25);
  if (q>3){ p=p*5; p=p^9; }
  int keep = p;
  p = p + 7;
  if ((p>>0)&1) cq_phi(0.7);
  if ((p>>1)&1) cq_phi(0.7);
  if ((p>>2)&1) cq_phi(0.7);
  if ((p>>3)&1) cq_phi(0.7);
  return cq_measure(p) + cq_measure(keep); }
int main(void){ (void)slice(); return 0; }
