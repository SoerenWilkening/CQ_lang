int slice(void){ int q=3,p=7; q=cq_theta(q,0.5); p=cq_theta(p,0.25);
  if (q>3){ p=p+3; p=p*5; p=p^9; p=p+1; p=p*7; p=p^2; }
  p = p + 7;
  for (int i=0;i<4;i++) if ((p>>i)&1) cq_phi(0.7);
  return cq_measure(p); }
int main(void){ (void)slice(); return 0; }
