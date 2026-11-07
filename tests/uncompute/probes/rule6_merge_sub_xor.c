int e(int k){ double a=0,b=0; cq_theta(&a,.3); cq_theta(&b,.7); long ia=(long)a,ib=(long)b; long r; if(k&1) r=ia-ib; else r=ib^ia; return (int)cq_measure(r); }
