/* angle select (folded if/else on one register) */
int slice(void){ int q=0; q=cq_theta(q,0.5); int r=0; r=cq_theta(r,0.2); int m=cq_measure(q);
  if(q>3) r=cq_theta(r,0.9); else r=cq_theta(r,0.3); return m+cq_measure(r); }
int main(void){(void)slice();return 0;}
