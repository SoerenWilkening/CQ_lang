int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ r=cq_theta(r,0.1); }
  int y=5; if (q>5) y=ext_f(7);
  int acc=0;
  { if((y>>0)&1) cq_phi(0.25); int s=cq_theta(r,0.2); acc+=cq_measure(s); }
  { if((y>>1)&1) cq_phi(0.25); int s=cq_theta(r,0.2); acc+=cq_measure(s); }
  { if((y>>2)&1) cq_phi(0.25); int s=cq_theta(r,0.2); acc+=cq_measure(s); }
  return cq_measure(y)+acc; }
int main(void){ (void)slice(5); return 0; }
