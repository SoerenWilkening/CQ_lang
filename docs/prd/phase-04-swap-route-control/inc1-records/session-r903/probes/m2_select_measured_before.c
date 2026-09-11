int main(void) {
  int q = cq_theta(0, 0.5);
  int m = cq_measure(q);
  int a = (q > 3) ? 2 : 5;
  return m + cq_measure(a);
}
