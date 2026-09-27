int h(int a, int k); int g(int a);
int main(int c, char **v) {
  int q = cq_theta(c, .5);
  int t = c + 1;
  int u = g(t);
  int r = u;
  if (c > 3) r = cq_theta(u, .2);
  return cq_measure(r) + cq_measure(q);
}
