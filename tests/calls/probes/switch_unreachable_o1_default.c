int e(int k){ char a=0; cq_theta(&a,.3); int r; switch(k&3){case 0: r=a+1; break; case 1: r=a^5; break; case 2: r=a+9; break; case 3: r=a*3; break;} return cq_measure(r); }
