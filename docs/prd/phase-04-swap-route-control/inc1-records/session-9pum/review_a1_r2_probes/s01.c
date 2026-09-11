int slice(void){ int q=0; q=cq_theta(q,0.5); int m=cq_measure(q); int a=(q==1)?2:5; return m+a; }
int main(void){(void)slice();return 0;}
