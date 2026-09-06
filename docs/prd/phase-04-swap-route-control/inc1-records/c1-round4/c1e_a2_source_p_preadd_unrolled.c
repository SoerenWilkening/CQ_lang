int slice(void){ int q=3,p=7; q=cq_theta(q,0.5); p=cq_theta(p,0.25);
  int r = p;
  if (q>3) { r = p*5; r = r^9; }
  int t = p + 7;
  if (((t)>>0)&1) cq_phi(0.7);
  if (((t)>>1)&1) cq_phi(0.7);
  if (((t)>>2)&1) cq_phi(0.7);
  if (((t)>>3)&1) cq_phi(0.7);
  return cq_measure(r) + cq_measure(t); }
int main(void){ (void)slice(); return 0; }
