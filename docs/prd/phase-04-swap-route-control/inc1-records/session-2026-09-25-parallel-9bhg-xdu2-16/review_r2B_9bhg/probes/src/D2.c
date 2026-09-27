int h(int a, int k); int g2(int a, int b);
int main(int c, char **v) {
  int q = cq_theta(c, .5);
  int t = h(q, c);
  int u = g2(t, q);
  int r = u;
  if (c > 3) r = cq_theta(u, .2);
  return cq_measure(r) + cq_measure(q);
}
