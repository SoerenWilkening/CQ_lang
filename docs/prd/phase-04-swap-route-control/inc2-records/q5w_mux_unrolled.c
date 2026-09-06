int slice(void){ int q=3; q=cq_theta(q,0.5); int m=5;
  switch(q){ case 0: m=11; break; case 1: m=22; break; }
  m = m + 7;
  if ((m>>0)&1) cq_phi(0.7); if ((m>>1)&1) cq_phi(0.7);
  if ((m>>2)&1) cq_phi(0.7); if ((m>>3)&1) cq_phi(0.7);
  return cq_measure(m); }
int main(void){ (void)slice(); return 0; }
