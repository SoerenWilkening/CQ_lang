double hf(double, double); double hfq(double, double);
int main(int c, char **v) {
  double x = (double)c;
  double q = cq_theta(x, .5);
  double y = hfq(q, x);
  double z = x + 1;
  double w = hfq(z, q);
  return (int)(cq_measure(w) + cq_measure(q) + cq_measure(y));
}
