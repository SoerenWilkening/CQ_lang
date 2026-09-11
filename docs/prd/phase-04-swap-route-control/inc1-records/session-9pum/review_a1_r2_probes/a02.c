int slice(void){ int q=0; q=cq_theta(q,0.5); if(q>3) cq_phi(0.3); return cq_measure(q); }
int main(void){(void)slice();return 0;}
