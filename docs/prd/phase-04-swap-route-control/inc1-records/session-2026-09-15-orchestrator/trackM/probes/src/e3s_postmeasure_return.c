#include "CQ.h"
/* E3 RETURN: a post-measure read RETURNED. Today a tainted non-i32 return declines / an
   i32 one ESCAPES (FreePoint treats a ret as an escape, so the rail is never freed). */
int f(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); (void)m; return q; }
int main(void){ return f(); }
