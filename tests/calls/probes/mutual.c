__attribute__((noinline)) static int odd(int n, int a);
__attribute__((noinline)) static int even(int n, int a) { if (n <= 0) return a; return 1 + odd(n - 1, a * 3); }
__attribute__((noinline)) static int odd(int n, int a) { if (n <= 0) return a + 1; return 2 + even(n - 1, a + 5); }
int mutual(int n0, double th, int a) {
  int n = n0;
  cq_theta(&n, th);
  return cq_measure(even(n & 3, a));
}
