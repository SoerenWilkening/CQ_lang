int slice(void){ int q=3; q=cq_theta(q,0.5); int m=5;
  switch(q){ case 0: m=11; break; case 1: m=22; break; }
  m = m + 7;
  for (int i=0;i<4;i++) if ((m>>i)&1) cq_phi(0.7);
  return cq_measure(m); }
int main(void){ (void)slice(); return 0; }
