/* r7 (GLPK glp_check_cnfsat as compiled, cnfsat_fn.ll): a K-loop B in the exit arm (tail) of a K-loop A; B's tail is entered
   from B's zero-trip guard too, so that block lies in both tails and is the inner unit's (rules 9, 14). Driver: a glp_prob
   image at the offsets the IR reads, every field a function of the quantum x. */
#include <string.h>
int glp_check_cnfsat(void *P);
struct col { char pad[24]; int kind, type; double lb, ub, coef; };
struct aij { char pad[16]; double val; char pad2[8]; struct aij *next; };
struct row { char pad[32]; int type; int pad1; double rhs; char pad2[8]; struct aij *ptr; };
struct prob { char pad[40]; double c0; char pad2[8]; int m, n; struct row **row; struct col **col; };
struct col cs[4];
struct col *cp[4];
struct row rs[4];
struct row *rp[4];
struct aij as[4];
struct prob P;
int f(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  P.n = x & 3;
  P.m = (x >> 2) & 1;
  P.c0 = (x >> 3) & 1;
  for (int k = 1; k < 4; k++) {
    cs[k].kind = 2;
    cs[k].type = 4;
    cs[k].lb = 0.0;
    cs[k].ub = 1.0;
    cs[k].coef = (x >> (3 + k)) & 1;
    cp[k] = &cs[k];
  }
  cs[1].kind = 2 + ((x >> 7) & 1);
  rs[1].type = 2 + ((x >> 8) & 1);
  rs[1].ptr = (x >> 9) & 1 ? &as[0] : 0;
  rs[1].rhs = (x >> 10) & 1;
  as[0].val = (x >> 11) & 1 ? 1.0 : -1.0;
  as[0].next = 0;
  rp[1] = &rs[1];
  P.row = rp;
  P.col = cp;
  return glp_check_cnfsat(&P);
}
