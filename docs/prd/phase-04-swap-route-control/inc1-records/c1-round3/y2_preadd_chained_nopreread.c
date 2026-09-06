/* y2 — y1 with the PRE-op name NOT read afterwards.  Must stay an ACCEPT and must
   discharge (the F-C1-1 capability), i.e. the tripwire must not over-fire. */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int q2=cq_theta(q,0.3);
  int a = q2 + 7;
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(r)+cq_measure(a); }
int main(void){ (void)slice(5); return 0; }
