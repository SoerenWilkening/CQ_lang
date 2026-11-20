/* cq-iaz30 (SQLite sqlite3AddColumn, reduced): a classically bounded loop with a quantum exit, entered only when
   n - 1 > 1 (classical); its normal exit runs `n -= 2` (its exit arm), a block also entered straight from the classical
   skip (n - 1 <= 1: the arm is the unit's tail). The tail's head is guarded by the skip's classical condition; the
   guard's skip edge into the continuation carries the unit's paths, and was read as an ordinary edge selecting among
   the continuation's incomings, a tail value among them. */
unsigned char map[16] = {0x80, 0x80, 0, 0x80, 0x80, 0x80, 0, 0x80, 0x80, 0, 0x80, 0x80, 0x80, 0x80, 0, 0x80};
int f(unsigned x0, double th, int n, int strict)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int k;
  if (strict < 2 && n >= 2 && (map[x & 15] & 0x80)) {
    for (k = 1; k < n - 1; k++)
      if (!(map[(x >> k) & 15] & 0x80))
        goto out;
    n -= 2;
  }
out:
  return n;
}
