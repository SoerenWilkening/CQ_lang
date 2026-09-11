/* drbq Inc-3 in-loop controlled-Ry arm, condition register MEASURED in the body */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u+1,0.1); int acc=0;
  for (int i=0;i<3;++i){ if(q>5) r=cq_theta(r,0.9); acc+=cq_measure(q); q=cq_theta(q,0.25); }
  return acc+cq_measure(r); }
int main(void){(void)slice(2);return 0;}
