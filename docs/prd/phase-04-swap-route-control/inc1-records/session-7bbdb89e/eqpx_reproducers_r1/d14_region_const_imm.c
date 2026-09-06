int slice(int u){ int r=cq_theta(u,0.3); int a=cq_theta(u,0.7);
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r = r ^ 7; }
  return cq_measure(a)+cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
