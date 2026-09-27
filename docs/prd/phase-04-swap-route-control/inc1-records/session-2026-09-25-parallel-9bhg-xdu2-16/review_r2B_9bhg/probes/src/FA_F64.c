double hf(double, double); double hfq(double, double);
int main(int c, char **v) {
  double x = (double)c;
  double q = cq_theta(x, .5);
  double y = hfq(q, x);
  double z = hf(y, x);
  double w = hfq(z, q);
  return (int)(cq_measure(w) + cq_measure(q) + cq_measure(y));
}
