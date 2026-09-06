volatile int off = 7;
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  q = q + off;
  for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
