/* x01c — x01's COMPARE twin: the cqrt_x bracket fires ONE gate, so inf is faithful. */
int slice(void) { int q=3; int r=7; q=cq_theta(q,0.5); r=cq_theta(r,0.25);
  if (q != 5) { r = cq_theta(r, __builtin_inf()); }
  return (int)cq_measure(q) + cq_measure(r); }
int main(void){(void)slice();return 0;}
