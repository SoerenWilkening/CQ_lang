int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y; switch(q){ case 1: y=3; break; case 2: y=9; break; default: y=5; }
  int w = y & 7;
  int a = cq_theta(u,0.7);
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r = r ^ w; }
  return cq_measure(a)+cq_measure(r)+cq_measure(y); }
int main(void){ (void)slice(5); return 0; }
