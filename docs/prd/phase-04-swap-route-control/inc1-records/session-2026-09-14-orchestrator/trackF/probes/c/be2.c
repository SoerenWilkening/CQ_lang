/* variant: a value ConstantRange can pin but that is not syntactically constant */
int main(void){ int q = cq_theta(3, 0.3); int t = (q & 3) / 4; int r = 0;
  if (q == 5) r = cq_theta(0, 0.9);
  return (int)cq_measure(r) + (int)cq_measure(t) + (int)cq_measure(q); }
