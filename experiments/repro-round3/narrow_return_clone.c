unsigned char a[8] = {1,2,3,4,5,6,7,8};
__attribute__((noinline)) static char g(unsigned x)
{
  return a[x];
}
char f(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  return g(x & 7);
}
