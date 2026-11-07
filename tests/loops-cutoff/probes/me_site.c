/* tests/loops-cutoff probe (CR rules 2, 14; owner, cq-47f8h): a cq_measure in the body of a K-loop with a quantum exit is
   identified by its call site. v bit 1 is b1, so !b1 stops the loop after trip 0: the K copies on trips no sample of the
   C program reaches execute the one site C does reach. */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int n=0; while ((v & 1) && !b1) { n += cq_measure(v); v >>= 1; n++; }
 return n;
}
/* the !b3 variant: bit 3 is reached after three shifts, so trips 1 to 3 are reached by some inputs */
int g(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int n=0; while ((v & 1) && !b3) { n += cq_measure(v); v >>= 1; n++; }
 return n;
}
