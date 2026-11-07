int e(int k){ char a=0,b=0,q=0; cq_theta(&a,.3); cq_theta(&b,.7); cq_theta(&q,.2); int ia=a; int r=ia*3; if(k&1){ r=ia-b; if(q&1) r+=2; else r=~r; } return cq_measure(r+1); }
