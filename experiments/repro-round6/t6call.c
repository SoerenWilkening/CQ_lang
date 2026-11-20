typedef unsigned long mp_limb_t;
void __gmpn_toom6h_mul(mp_limb_t *pp, const mp_limb_t *ap, long an, const mp_limb_t *bp, long bn, mp_limb_t *scratch);
mp_limb_t a[64], b[64], p[128], s[1024];
int t6(unsigned x0, double th, long an, long bn)
{
  unsigned x = x0;
  cq_theta(&x, th);
  a[0] = x;
  b[0] = x >> 1;
  __gmpn_toom6h_mul(p, a, an, b, bn, s);
  return (int)p[0];
}
