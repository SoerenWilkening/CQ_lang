/* cq-iaz30 (SQLite btreeBeginTrans, reduced): a K-loop on a classical arm (wrflag > 1) exits into a block it shares with
   the other arm of a quantum branch (pBlock = ...->db, the tail) and into the continuation, which also takes the
   classical skip's value (wrflag <= 1). The skip's output edge and the loop's meet at the quantum branch's other arm,
   before the continuation, so no join at the continuation takes the skip's value. */
struct Db { int x; };
struct Bt { struct Db *db; };
struct Lock { struct Bt *bt; struct Lock *next; };
struct Db d0, d1;
struct Bt b0 = {&d0}, b1 = {&d1}, b2 = {0};
struct Lock l2 = {&b1, 0}, l1 = {&b0, &l2}, l0 = {&b2, &l1};
struct Shared { int inTrans; int flags; struct Bt *writer; struct Lock *lock; } sh = {0, 0, &b1, &l0};
struct Bt *bts[4] = {&b0, &b1, &b2, &b0};
int nscan;
int f(unsigned x0, double th, int wrflag)
{
  unsigned x = x0;
  cq_theta(&x, th);
  sh.inTrans = x & 3;
  sh.flags = x & 4;
  struct Bt *p = bts[(x >> 3) & 3];
  struct Db *pBlock = 0;
  if (sh.flags == 0 && (wrflag == 0 || sh.inTrans != 2)) {
    if (wrflag > 1) {
      nscan++;
      for (struct Lock *it = sh.lock; it; it = it->next)
        if (it->bt != p) {
          pBlock = it->bt->db;
          break;
        }
    }
  } else {
    pBlock = sh.writer->db;
  }
  if (pBlock)
    return 262;
  return 0;
}
