/* cq-fi2wc (GLPK _glp_dlsym and the db loaders, reduced): two calls of a function another translation unit defines as
   noreturn (twodie_b.c), in one block: this unit's -O1 put no `unreachable` after the first. endAtNoreturn cut after
   each, and the first cut erased the second call, whose cut then read a freed instruction (a crash). */
void die(int);
int twodie(unsigned x0, double th)
{
  if (x0 == 3) {
    die(1);
    die(2);
  }
  unsigned x = x0;
  cq_theta(&x, th);
  return (int)(x * 2);
}
