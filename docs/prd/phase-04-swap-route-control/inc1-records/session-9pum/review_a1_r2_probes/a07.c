/* S-dagger after a compare SELECT (declines on main -- A.2's, must not move) */
int slice(void){ int q=0; q=cq_theta(q,0.5); int a=(q>3)?2:5; int q2=cq_theta(q,-0.5); return a+cq_measure(q2); }
int main(void){(void)slice();return 0;}
