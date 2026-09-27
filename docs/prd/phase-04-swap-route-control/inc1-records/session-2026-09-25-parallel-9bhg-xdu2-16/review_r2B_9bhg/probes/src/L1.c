int h(int a, int k);
int main(int c, char **v) {
  int q = cq_theta(c, .5);
  int t = h(q, c);
  int r = t;
  for (int i = 0; i < c; i++) r = cq_theta(r, .3);
  return cq_measure(r) + cq_measure(q);
}
