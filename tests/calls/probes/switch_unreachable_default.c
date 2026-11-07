int e(int k){ char a=0; cq_theta(&a,.3); int r; switch(k){case 0: r=a+1; break; case 1: r=a^5; break; case 2: r=a+9; break; default: __builtin_unreachable();} return cq_measure(r); }
