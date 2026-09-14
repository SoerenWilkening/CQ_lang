#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    int s = 0;
    _Bool b = 0;
    a = cq_theta(a, 0.5);
    b = cq_theta(b, 0.5);
    {
        b = cq_theta(b, 0.25);
        int r = cq_theta(7, 0.25);
        if (b) { r = cq_theta(r, 0.9); }
        s += cq_measure(r);
    }
    {
        b = cq_theta(b, 0.25);
        int r = cq_theta(7, 0.25);
        if (b) { r = cq_theta(r, 0.9); }
        s += cq_measure(r);
    }
    return cq_measure(a) + s + (int) cq_measure(b);
}
int main(void){(void)slice();return 0;}
