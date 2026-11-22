/* cq-mmen6 probe: nested classical arms with calls, a classical loop between them and the returns, an early return. */
__attribute__((noinline)) int g1(int v) { return v * 7 - 1; }
__attribute__((noinline)) int g2(int v) { return (v >> 1) + 9; }

int nest(int a, int b, int c, int n) {
  int x = a;
  cq_theta(&x, 0.7);
  int r = 1;
  if (c & 1) {
    r = g1(x);
    if (c & 2)
      r += g2(x + b);
    else
      r -= g1(x ^ b);
  }
  if (b < 0)
    return cq_measure(r);
  for (int i = 0; i < n; i++) {
    if ((c >> i) & 4)
      r ^= g2(x + i);
    if (i == b)
      return cq_measure(r - i);
  }
  return cq_measure(r + 3);
}
