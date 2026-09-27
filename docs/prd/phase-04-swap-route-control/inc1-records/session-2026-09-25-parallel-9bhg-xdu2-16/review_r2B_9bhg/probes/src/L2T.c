int h(int a, int k);
int main(int c, char **v) {
  int q = cq_theta(c, .5);
  int t = c + 1;
  int x = t;
  for (int i = 0; i < c; i++) x = x + q;
  return cq_measure(x) + cq_measure(q);
}
