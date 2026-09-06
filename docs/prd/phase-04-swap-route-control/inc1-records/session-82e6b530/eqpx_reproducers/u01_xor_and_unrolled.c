/* hand-unrolled TWIN of c1c_m_xor_and_noregion.c (K=3) */
int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);
  int w = y & 7;
  r = r ^ w; r = r ^ w; r = r ^ w;
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
int main(void){ (void)slice(5); return 0; }
