/* clearance probe Q: the 6.5 arm's CONDITION reads the loop's own rail register r */
int ext_f(int a);
int slice(int u){ int r=cq_theta(u,0.3);
  int y=5; if (r>5) y=ext_f(7);
  int w = y & 7;
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r)+cq_measure(y); }
int main(void){ (void)slice(5); return 0; }
