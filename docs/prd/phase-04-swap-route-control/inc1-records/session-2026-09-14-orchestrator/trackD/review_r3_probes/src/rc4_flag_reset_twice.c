int example(int n){ int q=cq_theta(0,0.25); int s=0; int first=1;
  for(int i=0;i<4;i++){ if(first){ int b=cq_theta(q,0.9); s+=cq_measure(b); first=0;} else s+=1;
    if(i==1) first=1; }
  return s; }
