int h(int a, int k);
int ext_f(int a);
int main(int c, char **v) {
  int q = cq_theta(c, .5);
  int y = 0;
  if (q > 5) y = ext_f(7);
  int t = h(y, c);
  return cq_measure(t) + cq_measure(q) + cq_measure(y);
}
