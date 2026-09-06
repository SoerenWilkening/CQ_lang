int slice(void){ int q=3,p=7; q=cq_theta(q,0.5); p=cq_theta(p,0.25);
  int c = p*5; c = c^9;
  int r = p;
  if (q>3) r = c;
  int t = c + 7;
  for (int i=0;i<4;i++) if (((t)>>i)&1) cq_phi(0.7);
  return cq_measure(r) + cq_measure(t); }
int main(void){ (void)slice(); return 0; }
