/* tests/calls probe (cq-sd95): musl's __polevll shape, in its own TU (no IPO specialisation at the caller). */
long double pol(long double x, const long double *P, int n) {
  long double y = *P++;
  do y = y * x + *P++; while (--n);
  return y;
}
