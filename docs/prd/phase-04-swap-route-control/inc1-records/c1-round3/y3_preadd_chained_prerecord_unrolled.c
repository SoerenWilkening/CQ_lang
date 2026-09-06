int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int q2=cq_theta(q,0.3);
  int a = q2 + 7;
  if((a>>0)&1) cq_phi(0.2); r=cq_theta(r,0.1);
  if((a>>1)&1) cq_phi(0.2); r=cq_theta(r,0.1);
  if((a>>2)&1) cq_phi(0.2); r=cq_theta(r,0.1);
  return cq_measure(q)+cq_measure(r)+cq_measure(a); }
int main(void){ (void)slice(5); return 0; }
