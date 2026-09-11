/* the condition operand is a QROM/array read; a different register is measured */
static const int T[4] = {1,2,3,4};
int slice(int u){ int q=cq_theta(u&3,0.5); int v=T[q&3]; int m=cq_measure(q);
  int a=(v>2)?2:5; return a+m; }
int main(void){(void)slice(2);return 0;}
