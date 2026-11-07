int e(int k){ char a=0,b=0; cq_theta(&a,.3); cq_theta(&b,.7); int ia=a,ib=b; int r; if(k&1) r=ia-ib; else r=ia+ib; return cq_measure(r); }
