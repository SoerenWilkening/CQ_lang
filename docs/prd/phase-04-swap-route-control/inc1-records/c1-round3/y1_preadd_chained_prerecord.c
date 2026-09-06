/* y1 — the PEELED parent has ONE use, but `lowerRotations` RAUWs the WHOLE chain
   onto ONE handle, so the handle acquires the EARLIER theta's reads.  The commit's
   `hasOneUse` is asked of `%3`; the read that matters is a use of `%2`. */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int q2=cq_theta(q,0.3);
  int a = q2 + 7;
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(q)+cq_measure(r)+cq_measure(a); }
int main(void){ (void)slice(5); return 0; }
