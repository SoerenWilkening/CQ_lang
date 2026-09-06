/* clearance probe T: an ARGUMENT immediate (k01 class) beside a 6.5 arm whose %out is NOT used by the loop (control) */
int ext_f(int a);
int slice(int u, int n){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);
  for(int i=0;i<3;i++){ r = r ^ n; }
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
int main(void){ (void)slice(5,3); return 0; }
