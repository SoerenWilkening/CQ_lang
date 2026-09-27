int h(int a, int k);
int main(int c, char **v) {
  int q = cq_theta(c, .5);
  int t = h(q, c);
  int r = t;
  for (int i = 0; i < 3; i++) {
    r = cq_theta(r, 0.2);
  }
  return cq_measure(r) + cq_measure(q);
}
