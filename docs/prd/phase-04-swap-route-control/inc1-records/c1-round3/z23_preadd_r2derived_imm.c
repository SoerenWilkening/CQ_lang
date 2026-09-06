int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);   /* %out: TAINTED at emission (round 1) */
  int w = y * 3;                  /* DERIVED from %out: untainted until ROUND 2 */
  int a = cq_theta(u,0.7);
  a = a + w;                      /* exactly one tainted operand at ROUND 1 */
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(a)+cq_measure(r)+cq_measure(y); }
int main(void){ (void)slice(5); return 0; }
