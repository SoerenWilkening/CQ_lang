int main(int argc, char **argv) {
  int q = cq_theta(0, 0.7);
  int r;
  if (q > 3) { r = 5; } else if (argc > 2) { r = 9; } else { r = 7; }
  return cq_measure(r);
}
