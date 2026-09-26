__attribute__((noinline)) int f(int x) { return x * 2 + 1; }
int main(void) {
  volatile int k = 7;
  int q = cq_theta(0, 0.7);
  int r;
  if (q > 3) { (void)k; r = 5; } else { r = 9; }
  return cq_measure(f(r));
}
