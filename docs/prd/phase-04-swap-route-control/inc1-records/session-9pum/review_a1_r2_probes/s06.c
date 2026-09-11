/* abort / controlled return */
int slice(int u){ int q=u; q=cq_theta(q,0.5); int m=cq_measure(q); if(q>3) return 1; return m+cq_measure(q); }
int main(void){(void)slice(2);return 0;}
