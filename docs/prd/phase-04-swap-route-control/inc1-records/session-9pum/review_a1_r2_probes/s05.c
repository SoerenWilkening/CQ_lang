/* value arm */
int slice(void){ int q=0; q=cq_theta(q,0.5); int m=cq_measure(q); int a=7; if(q>3) a=q*3+1; return m+a; }
int main(void){(void)slice();return 0;}
