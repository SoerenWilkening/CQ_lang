int ext_f(int a); int ext_h(int a, int k);
int main(int c, char **v) {
  int q = cq_theta(c, .5);
  int y = 0;
  if (q > 5) y = ext_f(7);
  int z = 0;
  if (q > 6) z = ext_h(y, c);
  return cq_measure(z) + cq_measure(y) + cq_measure(q);
}
