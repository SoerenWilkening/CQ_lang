/* cq-iaz30 (SQLite flattenSubquery, reduced): a classical argument tested twice (`c != 0`, two compares in the IR). A
   guard planned on one of them skips a block; its skip edge established no fact over the other's atom, so a later
   block's flag read a quantum atom of the skipped block on the skip path. */
struct S { unsigned char a, b, c, d; };
struct S tab[4] = {{0, 1, 0, 2}, {1, 0, 0, 3}, {0, 0, 1, 4}, {1, 1, 1, 5}};
int f(unsigned x0, int c, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  struct S *s = &tab[x & 3];
  int qa = s->a != 0;
  if (!qa && (c != 0 || s->b > 0))
    return 1;
  if (c != 0 && s->c != 0)
    return 2;
  if (qa ? s->d == 5 : (s->b == 0 && s->d > 2))
    return 3;
  return 4;
}
