/* cq-iaz30 (SQLite allocateBtreePage, reduced): a phi whose only defined incoming is minted in a classical arm (mode
   == 1), undef on the other edges, read after the join (here in a K-loop's exit). Its merge was that one value as it
   is, which does not reach the join's later readers on the other classical paths. */
int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
__attribute__((noinline)) int look(unsigned k) { return tbl[k & 7]; }
int f(unsigned x0, double th, int mode)
{
  unsigned x = x0;
  cq_theta(&x, th);
  int v, have = 0, s0 = 0;
  switch (mode) {
  case 1:
    if (x & 1) {
      v = look(x >> 1);
      have = v != 9;
    }
    break;
  case 2:
    s0 = 7;
    break;
  default:
    break;
  }
  int s = s0;
  for (unsigned i = 0; i < (x >> 4 & 7); i++) {
    if (have && v == tbl[i])
      return v + 100;
    s += tbl[i];
  }
  return s;
}
