long double hfl(long double, long double); long double hflq(long double, long double);
int main(int c, char **v) {
  long double x = (long double)c;
  long double q = cq_theta(x, .5);
  long double q2 = cq_theta(x + 2, .25);
  long double y = hflq(q, x);
  long double z = hflq(y, q2);
  long double u = x + 1;
  long double w = hflq(u, y);
  return (int)(cq_measure(w) + cq_measure(q2));
}
