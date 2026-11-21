/* The lowered library of the arrangement tests (rule 27, owner ruling 2026-11-20). */

/* A loop bounded by an argument, through a pointer argument. */
long sum_to(const long *a, long n) {
  long s = 0;
  for (long i = 0; i < n; i++)
    s += a[i];
  return s;
}

/* Two integers, no memory. */
long axpb(long a, long x, long b) { return a * x + b; }

/* Seven scalar formals of all three classes: class arrangements only. */
long mix7(const long *p, long n, long step, double w, double c, int neg, const long *q) {
  long s = 0;
  for (long i = 0; i < n; i += step)
    s += p[i] - q[i];
  double t = w * (double)s + c;
  long r = (long)t;
  return neg ? -r : r;
}

/* A loop bounded by a classical argument around quantum arithmetic. */
long horner(long x, long n) {
  long s = 0;
  for (long i = 0; i < n; i++)
    s = s * x + i;
  return s;
}
