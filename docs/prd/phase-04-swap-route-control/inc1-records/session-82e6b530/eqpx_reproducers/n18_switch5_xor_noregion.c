int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y; switch(q){ case 1: y=3; break; case 4: y=9; break; case 7: y=11; break;
                    case 13: y=21; break; case 19: y=33; break; default: y=5; }
  int w = y & 7;
  for(int i=0;i<3;i++){ r = r ^ w; }
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
int main(void){ (void)slice(5); return 0; }
