/* measure on a DISJOINT branch that cannot reach the region */
int opaque(void);
int slice(int u){ int q=cq_theta(u,0.5); int acc=0;
  if (opaque()) { acc = cq_measure(q); } else { if (q>5) cq_phi(0.3); acc = cq_measure(q); }
  return acc; }
int main(void){(void)slice(2);return 0;}
