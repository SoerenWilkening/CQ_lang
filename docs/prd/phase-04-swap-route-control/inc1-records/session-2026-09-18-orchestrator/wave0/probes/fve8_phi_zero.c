int slice(int k) {
  int q = cq_theta(3, 0.4);
  int u = 0;
  if (k > 1) u = q;
  return cq_measure(u) + cq_measure(q);
}
int main(void) { return slice(2); }
