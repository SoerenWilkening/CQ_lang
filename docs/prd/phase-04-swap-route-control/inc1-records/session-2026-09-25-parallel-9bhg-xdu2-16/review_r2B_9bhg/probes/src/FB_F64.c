double hf(double, double); double hfq(double, double);
int main(int c, char **v) {
  double x = (double)c;
  double q = cq_theta(x, .5);
  double q2 = cq_theta(x + 2, .25);
  double y = hfq(q, x);
  double z = hfq(y, q2);
  double u = hf(z, x);
  double w = hfq(u, y);
  return (int)(cq_measure(w) + cq_measure(q2));
}
