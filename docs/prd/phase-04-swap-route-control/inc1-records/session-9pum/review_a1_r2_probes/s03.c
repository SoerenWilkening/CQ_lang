/* nest */
int slice(void){ int q=0; q=cq_theta(q,0.5); int r=0; r=cq_theta(r,0.2); int m=cq_measure(q);
  if(q>3){ cq_phi(0.1); if(r>2) cq_phi(0.2); } return m+cq_measure(r); }
int main(void){(void)slice();return 0;}
