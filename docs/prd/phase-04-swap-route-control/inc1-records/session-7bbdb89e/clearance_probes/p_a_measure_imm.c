/* clearance probe A: the immediate is a cq_measure RESULT taken inside the loop (classical per iteration) */
int slice(int u){ int r=cq_theta(u,0.3); int s=cq_theta(u,0.7);
  for(int i=0;i<3;i++){ int m = cq_measure(s); r = r ^ m; }
  return cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
