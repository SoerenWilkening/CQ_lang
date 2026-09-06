/* the same in-body xor with NO in-body region, so ROUND-1 tryCaseA claims the loop. */
int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);
  int w = y * 3;
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
int main(void){ (void)slice(5); return 0; }
