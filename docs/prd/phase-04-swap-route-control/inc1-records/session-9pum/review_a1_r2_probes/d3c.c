/* drbq Inc-4 controlled STATE PREP with the condition measured before */
int slice(int u){ int q=cq_theta(u,0.5); int m=cq_measure(q); int r=3;
  if(q>5) r=cq_theta(7,0.9); return m+cq_measure(r); }
int main(void){(void)slice(2);return 0;}
