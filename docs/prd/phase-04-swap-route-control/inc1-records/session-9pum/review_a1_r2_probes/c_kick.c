int slice(int u){ int r=cq_theta(u,0.25); int r2=cq_theta(r,0.9); if(r>5) cq_phi(0.3); return cq_measure(r2); }
int main(void){(void)slice(2);return 0;}
