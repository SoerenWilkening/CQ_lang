int h(int a, int k);
int main(int c, char **v) {
  int q = cq_theta(c, .5);
  int t = c + 1;
  int r = cq_theta(t, 0.1);
  for (int i = 0; i < 3; i++) {
    r = cq_theta(r, 0.2);
    if (r == 5) cq_phi(0.7);
  }
  return cq_measure(r) + cq_measure(q);
}
