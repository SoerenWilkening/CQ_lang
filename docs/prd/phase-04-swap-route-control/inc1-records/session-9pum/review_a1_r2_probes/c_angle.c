int slice(int u){ int r=cq_theta(u,0.25); int r2=cq_theta(r,0.9); int x=cq_theta(u+1,0.1);
  if(r>5) x=cq_theta(x,0.9); else x=cq_theta(x,0.3); return cq_measure(r2)+cq_measure(x); }
int main(void){(void)slice(2);return 0;}
