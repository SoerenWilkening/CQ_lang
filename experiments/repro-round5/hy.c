/* cq-iaz30 (GSL hyperg_1F1_ab_neg, reduced) */
#include <math.h>
struct R { double val, err; };
__attribute__((noinline)) static int s1(double a, double b, double x, struct R *r)
{
  r->val = a + b * x;
  r->err = 0;
  return a > b;
}
__attribute__((noinline)) static int em(double x, double e, double v, double w, struct R *r)
{
  r->val = v * x;
  r->err = w + e;
  return x > 3;
}
__attribute__((noinline)) static int s2(double a, double b, double x, struct R *r)
{
  r->val = a - x;
  r->err = b;
  return 2;
}
__attribute__((noinline)) static int ab_neg(double a, double b, double x, struct R *result)
{
  const double bma = b - a;
  const double abs_x = fabs(x), abs_a = fabs(a), abs_b = fabs(b);
  const double size_a = abs_a > 1.0 ? abs_a : 1.0;
  const double size_b = abs_b > 1.0 ? abs_b : 1.0;
  if ((abs_a < 10.0 && abs_b < 10.0 && abs_x < 5.0) || (b > 0.8 * size_a * fabs(x)))
    return s1(a, b, x, result);
  else if (x > 0.0 && size_b > size_a && size_a * log(M_E * x / size_b) < -29.0)
    return s1(a, b, x, result);
  else if ((abs_x < 5.0 && fabs(bma) < 10.0 && abs_b < 10.0) || (b > 0.8 * fmax(fabs(bma), 1.0) * abs_x)) {
    struct R K;
    int stat_K = s1(bma, b, -x, &K);
    int stat_e = em(x, 1e-16 * fabs(x), K.val, K.err, result);
    return stat_e ? stat_e : stat_K;
  } else if (x < -30.0 && fmax(fabs(a), 1.0) * fmax(fabs(1.0 + a - b), 1.0) < 0.99 * fabs(x))
    return s2(a, b, x, result);
  return s1(b - a, b, -x, result);
}
struct R out;
int f(unsigned q0, double a, double b, double x, double th)
{
  unsigned q = q0;
  cq_theta(&q, th);
  if (q & 1)
    return ab_neg(a, b, x, &out);
  return 0;
}
