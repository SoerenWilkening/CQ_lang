int main(int argc, char **argv) {
  int q = cq_theta(0, 0.7);
  int acc = 0;
  for (int i = 0; i < 3; i++) {
    int d;
    if (q > i) { volatile int z = 1; d = 2; } else { d = 1; }
    acc += d;
  }
  return cq_measure(acc);
}
