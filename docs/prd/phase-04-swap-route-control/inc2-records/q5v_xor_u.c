int slice(void){ int q=3,p=7,r=9; q=cq_theta(q,0.5); p=cq_theta(p,0.25); r=cq_theta(r,0.3);
  int m = (q>5) ? p : r;
  m = m ^ 7;
  if ((m>>0)&1) cq_phi(0.7); if ((m>>1)&1) cq_phi(0.7);
  if ((m>>2)&1) cq_phi(0.7); if ((m>>3)&1) cq_phi(0.7);
  return cq_measure(m); }
int main(void){ (void)slice(); return 0; }
