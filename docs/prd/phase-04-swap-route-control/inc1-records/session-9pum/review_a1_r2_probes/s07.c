/* compound condition tree, one leaf measured */
int slice(void){ int q=0; q=cq_theta(q,0.5); int r=0; r=cq_theta(r,0.2); int m=cq_measure(r);
  if(q>3 && r<9) cq_phi(0.3); return m+cq_measure(q); }
int main(void){(void)slice();return 0;}
