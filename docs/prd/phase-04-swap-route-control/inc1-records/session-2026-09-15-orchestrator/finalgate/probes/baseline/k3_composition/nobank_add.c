volatile int off = 3;
int slice(void){
    int a = 0;
    a = cq_theta(a, 0.5);
    for (int i = 0; i < 2; ++i) {
        a = a + off;
    }
    return cq_measure(a);
}
int main(void){(void)slice();return 0;}
