#include <stdint.h>
long A[8], B[8];
__attribute__((noinline)) void keep(long *b) { B[0] = (long)b; }
/* legal: b is made by integer arithmetic, and every access b[i + 2] is inside p's object */
long f7(unsigned char q0, long *p) { unsigned char q = q0; cq_theta(&q, 0.5); long *b = (long *)((uintptr_t)p - 16); keep(b); return b[(q & 3) + 2]; }
