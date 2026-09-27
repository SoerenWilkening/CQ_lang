double hf(double, double); double hfq(double, double);
int main(int c, char **v) {
  double x = (double)c;
  double q = cq_theta(x, .5);
  double z = x + 1;
  double y = hfq(z, q);
  double r = y;
  if (c > 3) r = cq_theta(y, .2);
  return (int)(cq_measure(r) + cq_measure(q));
}
