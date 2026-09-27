long double hfl(long double, long double); long double hflq(long double, long double);
int main(int c, char **v) {
  long double x = (long double)c;
  long double q = cq_theta(x, .5);
  long double y = hflq(q, x);
  long double z = x + 1;
  long double w = hflq(z, q);
  return (int)(cq_measure(w) + cq_measure(q) + cq_measure(y));
}
