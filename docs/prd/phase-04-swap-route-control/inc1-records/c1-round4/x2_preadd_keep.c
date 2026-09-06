int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int keep = q;
  q = q + 7;
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(keep)+cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
