int example(int n){ int q=cq_theta(0,0.25); int s=0;
  for(int i=0;i<4;i++){ if(i==0 && n>2){ int b=cq_theta(q,0.9); s+=cq_measure(b);} else s+=1; }
  return s; }
