volatile int off = 3;
int slice(void){
    int a = 0, acc = 0;
    a = cq_theta(a, 0.5);
    for (int i = 0; i < 2; ++i) { acc = acc + a; a = cq_theta(a, 0.25); }
    return cq_measure(acc) + cq_measure(a);
}
int main(void){(void)slice();return 0;}
