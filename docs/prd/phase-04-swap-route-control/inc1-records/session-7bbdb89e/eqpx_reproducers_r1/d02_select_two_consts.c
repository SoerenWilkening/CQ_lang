int slice(int u){ int r=cq_theta(u,0.3);
  int w = (u > 2) ? 9 : 5;
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
