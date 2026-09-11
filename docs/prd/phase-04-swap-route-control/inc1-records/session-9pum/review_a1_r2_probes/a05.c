/* mirror: derived measured, parent controls (c7 class) */
int slice(void){ int q=0; q=cq_theta(q,0.5); int t=q^9; int m=cq_measure(t); int a=(q>5)?2:5; return m+a+cq_measure(q); }
int main(void){(void)slice();return 0;}
