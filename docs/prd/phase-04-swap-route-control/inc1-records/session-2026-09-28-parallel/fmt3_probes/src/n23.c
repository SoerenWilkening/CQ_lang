#include <stdlib.h>
#include <stdbool.h>
/* ArmClassify's "(b) ONE CONTENT ARM ONLY" clause (a two-arm if/else on a bare _Bool RAIL condition),
   which its comment called UNREACHABLE FROM PLAIN C because -O1 merged the two arms into an angle select */
int main(int c, char **v) { int m = atoi(v[1]); bool b = cq_theta((bool)(m & 1), .5); int r = cq_theta(3, .2);
  if (b) r = cq_theta(r, .9); else r = cq_theta(r, .3);
  return cq_measure(r) + cq_measure(b); }
