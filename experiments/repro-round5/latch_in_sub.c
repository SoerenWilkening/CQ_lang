/* cq-iaz30 (SQLite exprAnalyzeOrTerm, reduced): a K-loop whose latch lies in an inner K-loop: the inner loop's exit is
   the outer back edge. The outer trip's continue test read the inner exit test's atom, a rail of the inner rolled trip,
   at the end of the outer trip, where it does not reach. */
struct S { unsigned char op, n, t[4]; };
struct S cl[2] = {{1, 3, {3, 5, 0, 6}}, {2, 2, {7, 4, 9, 9}}};
static unsigned char *nth(struct S *s, unsigned i)
{
  if (s->op == 1)
    return i == 0 ? &s->n : 0;
  return i < s->n ? &s->t[i] : 0;
}
int g(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  struct S *a = &cl[x & 1], *b = &cl[(x >> 1) & 1];
  unsigned cnt = 0;
  unsigned char *p, *q;
  if (x & 4)
    for (unsigned i = 0; (p = nth(a, i++)) != 0;)
      for (unsigned j = 0; (q = nth(b, j)) != 0; j++) {
        if ((*q ^ *p) & 1)
          continue;
        cnt += *q + *p;
      }
  return cnt;
}
