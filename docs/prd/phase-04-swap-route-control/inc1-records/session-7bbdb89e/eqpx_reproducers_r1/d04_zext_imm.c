unsigned char gc = 9;
int slice(int u){ int r=cq_theta(u,0.3);
  unsigned char c = gc; int w = c;
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
