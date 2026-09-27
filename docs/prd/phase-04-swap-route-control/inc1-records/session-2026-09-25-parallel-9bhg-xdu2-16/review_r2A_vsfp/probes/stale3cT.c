__attribute__((noinline)) int f(int x) { return x * 2 + 1; }
int main(void) {
  int q = cq_theta(0, 0.7);
  int r;
  if (q > 3) { r = 5; } else { r = 9; }
  return cq_measure(f(r));
}
