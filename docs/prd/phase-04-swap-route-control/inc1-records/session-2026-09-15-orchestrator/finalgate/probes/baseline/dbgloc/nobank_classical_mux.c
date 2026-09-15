volatile int off = 3;
int slice(void){
    int x = 0, y = 0;
    x = cq_theta(x, 0.5);
    y = cq_theta(y, 0.25);
    int r;
    if (off > 1) { off = 1; r = x; } else { off = 2; r = y; }
    return cq_measure(r);
}
int main(void){(void)slice();return 0;}
