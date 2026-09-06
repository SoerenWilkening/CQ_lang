/* v7 — the later read of the shared wire is a `ret` of the pre-op name (an ESCAPE). */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int q2=cq_theta(q,0.3);
  int a = q2 + 7;
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  (void)cq_measure(a); (void)cq_measure(r);
  return q; }
int main(void){ (void)slice(5); return 0; }
