unsigned f(unsigned x0, double th, unsigned a, unsigned b)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned ah;
  a = a % 16 + 1;
  for (;;) {
    if (a < 4) { ah = a * 3; break; }
    x += a;
    if (a == 9) return x;
    if (b < 4) { ah = b; break; }
    a = a - 1;
  }
  return a + b + ah;
}
