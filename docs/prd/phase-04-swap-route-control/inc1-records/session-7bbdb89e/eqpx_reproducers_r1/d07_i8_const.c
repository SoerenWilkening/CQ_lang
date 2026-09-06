int slice(int u){ signed char r=cq_theta((signed char)u,0.3);
  for(int i=0;i<3;i++){ r = r ^ 7; }
  return cq_measure(r); }
int main(void){ (void)slice(5); return 0; }
