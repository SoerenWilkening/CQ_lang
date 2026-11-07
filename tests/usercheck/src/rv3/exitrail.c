#include <stdlib.h>
/* cq-byjad (rule 16): a noreturn call with a rail argument and no quantum predicate is the effect entry of its
   name under an alloc_i1(true) seed, then abort_i1 of that seed. The C program ends in exit(c) and logs no effect;
   ours has that one entry, whose status field is the C program's exit status. */
int f(int k){ char c=0; cq_theta(&c,.5); if(k&1) exit(c); return cq_measure(c); }
