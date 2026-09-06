int slice(void){ int q=3,p=7,r=9; q=cq_theta(q,0.5); p=cq_theta(p,0.25); r=cq_theta(r,0.3);
  int m = (q>5) ? p : r;
  
  for (int i=0;i<4;i++) if ((m>>i)&1) cq_phi(0.7);
  return cq_measure(m); }
int main(void){ (void)slice(); return 0; }
