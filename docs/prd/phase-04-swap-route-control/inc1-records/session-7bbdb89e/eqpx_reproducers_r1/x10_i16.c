int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); short r=cq_theta((short)u,0.3);
  int y=5; if (q>5) y=ext_f(7);
  short w = (short)(y & 7);
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
int main(void){ (void)slice(5); return 0; }
