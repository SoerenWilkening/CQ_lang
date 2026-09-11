/* region inside the loop, measure AFTER the loop */
int slice(int u){ int q=cq_theta(u,0.5);
  for (int i=0;i<3;++i){ if(q>5) cq_phi(0.3); }
  return cq_measure(q); }
int main(void){(void)slice(2);return 0;}
