int main(int argc, char **argv) {
  (void)argv;
  int q = cq_theta(0, 0.5);
  int m = cq_measure(q);
  if (argc > 1) m += 1;
  if (q > 3) cq_phi(0.3);
  return m;
}
