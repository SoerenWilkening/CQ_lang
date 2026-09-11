/* derived out-of-place rail controls, parent measured (c1 class) */
int slice(void){ int q=0; q=cq_theta(q,0.5); int t=q^9; int m=cq_measure(q); int a=(t>5)?2:5; return m+a+cq_measure(t); }
int main(void){(void)slice();return 0;}
