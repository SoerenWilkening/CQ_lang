int example(int u){ int q=cq_theta(0,0.25); int s=0;
  if(u>0){ for(int i=u;i<u+3;i++){ if(i==u){ int b=cq_theta(q,0.9); s+=cq_measure(b);} else s+=1; } }
  return s; }
