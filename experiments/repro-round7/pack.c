/* GLPK npp_sat_is_pack_ineq (reduced, its code kept): two K-loops (list walks from a quantum start) in the two arms of a
   quantum branch, whose exit arms share a tail block into one join; each exit arm reads its loop header's per-trip atom
   (aij != NULL) again after the loop. */
struct col { int is_int; double lb, ub; };
struct aij { struct col *col; double pad; double val; double pad2; struct aij *r_next; };
struct row { double pad; double pad1; double lb, ub; struct aij *ptr; };
static struct col cols[4] = {{1, 0, 1}, {1, 0, 1}, {0, 0, 1}, {1, 0, 2}};
static struct aij as[6];
static struct row r;

int bin_comb(struct row *row)
{
  struct aij *aij;
  for (aij = row->ptr; aij != 0; aij = aij->r_next) {
    if (!(aij->val == +1.0 || aij->val == -1.0))
      return 0;
    struct col *col = aij->col;
    if (!(col->is_int && col->lb == 0.0 && col->ub == 1.0))
      return 0;
  }
  return 1;
}

int num_pos(struct row *row)
{
  int num = 0;
  for (struct aij *aij = row->ptr; aij != 0; aij = aij->r_next)
    if (aij->val > 0.0)
      num++;
  return num;
}

int num_neg(struct row *row)
{
  int num = 0;
  for (struct aij *aij = row->ptr; aij != 0; aij = aij->r_next)
    if (aij->val < 0.0)
      num++;
  return num;
}

int is_pack(struct row *row)
{
  if (row->lb == -1e300 && row->ub != +1e300) {
    if (bin_comb(row))
      if (row->ub == 1.0 - num_neg(row))
        return 1;
  } else if (row->lb != -1e300 && row->ub == +1e300) {
    if (bin_comb(row))
      if (row->lb == num_pos(row) - 1.0)
        return 2;
  }
  return 0;
}

int pack(unsigned x0, unsigned y0, double th)
{
  unsigned x = x0, y = y0;
  cq_theta(&x, th);
  for (int k = 0; k < 6; k++) {
    as[k].col = &cols[(y >> (2 * k)) & 3];
    as[k].val = (x >> k) & 1 ? -1.0 : 1.0;
    as[k].r_next = k < 5 && ((x >> (k + 8)) & 1) ? &as[k + 1] : 0;
  }
  r.ptr = (x >> 6) & 1 ? &as[(x >> 14) & 3] : 0;
  r.lb = (y >> 20) & 1 ? -1e300 : (double)((y >> 24) & 3);
  r.ub = (y >> 21) & 1 ? 1e300 : (double)((y >> 26) & 3);
  return is_pack(&r);
}
