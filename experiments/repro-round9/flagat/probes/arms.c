/* cq-mmen6 probe: items under classical conditions (calls in classical arms) placed at several returns, past the
   joins of later arms. */
__attribute__((noinline)) int h1(int v) { return v * 3 + 1; }
__attribute__((noinline)) int h2(int v) { return (v ^ 5) - 2; }

int arms(int a, int c1, int c2, int c3, int n) {
  int x = a;
  cq_theta(&x, 0.5);
  int r = 0;
  if (c1 & 1)
    r += h1(x);
  if (c2 & 1)
    r ^= h2(x + 7);
  if (c3 & 1)
    r += h1(x * x);
  if (c1 & 2)
    r -= h2(x << 2);
  for (int i = 0; i < n; i++)
    if (c3 & (2 << i))
      r += h1(x + i);
  if (c1 & 4)
    return cq_measure(r + 1);
  if (c2 & 2)
    r -= h2(x * 5);
  return cq_measure(r);
}
