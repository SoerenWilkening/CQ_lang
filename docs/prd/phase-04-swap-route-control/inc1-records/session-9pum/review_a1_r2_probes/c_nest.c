int slice(int u){ int r=cq_theta(u,0.25); int r2=cq_theta(r,0.9); int s=cq_theta(u+1,0.2);
  if(r>5){ cq_phi(0.1); if(s>2) cq_phi(0.2); } return cq_measure(r2)+cq_measure(s); }
int main(void){(void)slice(2);return 0;}
