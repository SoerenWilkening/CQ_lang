int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y = (q>5) ? 11 : 5;
  int w = y & 7;
  r = r ^ w; r = r ^ w; r = r ^ w;
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
int main(void){ (void)slice(5); return 0; }
