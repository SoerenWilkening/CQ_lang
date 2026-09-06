/* v3 — a THREE-deep theta chain; the MIDDLE member is measured after the loop. */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int q2=cq_theta(q,0.3);
  int q3=cq_theta(q2,0.4);
  int a = q3 + 7;
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(q2)+cq_measure(r)+cq_measure(a); }
int main(void){ (void)slice(5); return 0; }
