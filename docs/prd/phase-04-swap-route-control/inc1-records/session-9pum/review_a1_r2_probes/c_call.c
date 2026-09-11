int ext(int);
int slice(int u){ int r=cq_theta(u,0.25); int r2=cq_theta(r,0.9); int w=11; if(r>5) w=ext(3); return w+cq_measure(r2); }
int main(void){(void)slice(2);return 0;}
