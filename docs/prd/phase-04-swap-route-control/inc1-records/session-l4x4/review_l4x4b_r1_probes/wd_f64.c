int slice(void) { _Bool b=0; double r=7; b=cq_theta(b,0.5); r=cq_theta(r,0.25);
  if (b) { r = cq_theta(r, 0.9); }
  return (int)cq_measure(b) + (int)cq_measure(r); }
int main(void){(void)slice();return 0;}
