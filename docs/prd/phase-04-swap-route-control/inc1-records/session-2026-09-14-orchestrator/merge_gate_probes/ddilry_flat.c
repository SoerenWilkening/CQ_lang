#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    int s = 0;
    a = cq_theta(a, 0.5);
    int i = 0;
    {
        int r = cq_theta(7, 0.25);
        if ((a >> i) & 1) { r = cq_theta(r, 0.9); }
        s += cq_measure(r);
    }
    i = i + 1;
    {
        int r = cq_theta(7, 0.25);
        if ((a >> i) & 1) { r = cq_theta(r, 0.9); }
        s += cq_measure(r);
    }
    i = i + 1;
    a = cq_theta(a, 0.9);
    return cq_measure(a) + s;
}
int main(void){(void)slice();return 0;}
