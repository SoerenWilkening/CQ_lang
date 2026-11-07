int e(int k){ char a=0,b=0,q=0; cq_theta(&a,.3); cq_theta(&b,.7); cq_theta(&q,.2); int r=b; if(k&1){ r=a-b; r=r^(q&1); } return cq_measure(r+1); }
