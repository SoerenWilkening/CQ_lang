int e(int k){ char a=0,b=0,c=0; cq_theta(&a,.3); cq_theta(&b,.7); cq_theta(&c,.2); int ia=a,ib=b,ic=c; int r; if(k==0) r=ia+ib; else if(k==1) r=ib-ic; else r=ic^ia; return cq_measure(r); }
