__attribute__((noinline)) int f(int x) { return x * 2 + 1; }
int main(int argc, char **argv) {
  int q = cq_theta(0, 0.7);
  int r;
  if (q > 3) { volatile int z = 1; r = 5; } else { r = 9; }
  volatile int w = argc; int u = w;
  return cq_measure(f(r)) + u;
}
