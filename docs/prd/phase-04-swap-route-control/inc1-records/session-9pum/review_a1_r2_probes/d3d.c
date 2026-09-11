/* 6.5 classical-call arm, a NON-condition register measured before (must accept) */
int ext(int);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u+1,0.2); int m=cq_measure(r);
  int w=11; if(q>5) w=ext(3); return m+w+cq_measure(q); }
int main(void){(void)slice(2);return 0;}
