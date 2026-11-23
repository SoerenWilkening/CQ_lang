struct R { long a; int d; };
__attribute__((noinline)) struct R rank(unsigned x0, double th, int y)
{
  unsigned x = x0;
  cq_theta(&x, th);
  struct R r = { (long)(x | 0x10000) << 8, (int)x + y };
  return r;
}
int f(unsigned x0, double th, int y)
{
  struct R r = rank(x0, th, y);
  return (int)r.a * 3 + r.d;
}
