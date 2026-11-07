/* cq-by8qu: an `unreachable` reached (here the switch's default) is C undefined as LLVM defines it: those inputs are
   outside the domain, never sampled; the valid ones (k < 3) still compare, so a wrong arm is rejected. */
int f(int k){ char a=0; cq_theta(&a,.3); int r; switch(k){case 0: r=a+1; break; case 1: r=a^5; break; case 2: r=a+9; break; default: __builtin_unreachable();} return cq_measure(r); }
