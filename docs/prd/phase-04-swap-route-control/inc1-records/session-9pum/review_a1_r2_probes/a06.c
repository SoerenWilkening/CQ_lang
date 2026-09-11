/* S-dagger after a compare PHASE region (shipped accept) */
int slice(void){ int q=0; q=cq_theta(q,0.5); if(q>3) cq_phi(0.3); int q2=cq_theta(q,-0.5); return cq_measure(q2); }
int main(void){(void)slice();return 0;}
